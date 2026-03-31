import 'dart:async';
import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:data_table_2/data_table_2.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../websocket/websocket_template_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/consts.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/models/mqtt_request_model.dart';
import 'package:apidash/widgets/widgets.dart';
import 'package:apidash/widgets/mqtt_topic_autocomplete.dart';

class EditMQTTRequestPane extends ConsumerStatefulWidget {
  const EditMQTTRequestPane({super.key, this.showViewCodeButton = true});

  final bool showViewCodeButton;

  @override
  ConsumerState<EditMQTTRequestPane> createState() =>
      _EditMQTTRequestPaneState();
}

class _EditMQTTRequestPaneState extends ConsumerState<EditMQTTRequestPane> {
  late final TextEditingController _clientIdCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _publishTopicCtrl;
  late final TextEditingController _publishPayloadCtrl;
  late final TextEditingController _lastWillTopicCtrl;
  late final TextEditingController _lastWillMessageCtrl;
  String _publishContentType = 'json';

  bool _isValidJson = true;
  String? _jsonError;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final m = ref.read(mqttRequestProvider);
    _clientIdCtrl = TextEditingController(text: m.clientId);
    _userCtrl = TextEditingController(text: m.username);
    _passCtrl = TextEditingController(text: m.password);
    _publishTopicCtrl = TextEditingController(text: m.publishTopic);
    _publishPayloadCtrl = TextEditingController(text: m.publishPayload);
    _lastWillTopicCtrl = TextEditingController(text: m.lastWillTopic);
    _lastWillMessageCtrl = TextEditingController(text: m.lastWillMessage);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();

    for (final c in [
      _clientIdCtrl,
      _userCtrl,
      _passCtrl,
      _publishTopicCtrl,
      _publishPayloadCtrl,
      _lastWillTopicCtrl,
      _lastWillMessageCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _validateJson(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      try {
        if (value.trim().isNotEmpty) {
          jsonDecode(value);
        }
        setState(() {
          _isValidJson = true;
          _jsonError = null;
        });
      } catch (e) {
        setState(() {
          _isValidJson = false;
          _jsonError = e.toString().contains('FormatException:')
              ? e.toString().split('FormatException: ')[1]
              : e.toString();
        });
      }
    });
  }

  // Templates

  List<Map<String, dynamic>> _templates = [];
  String? _currentRequestId;

  void _checkRequestId(String newId) {
    if (_currentRequestId != newId) {
      _currentRequestId = newId;
      _loadTemplates(newId);
    }
  }

  Future<void> _loadTemplates(String requestId) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('mqtt_publish_templates_$requestId');
    if (str != null) {
      try {
        final List<dynamic> list = jsonDecode(str);
        setState(() {
          _templates = list.cast<Map<String, dynamic>>();
        });
      } catch (_) {
        setState(() {
          _templates = [];
        });
      }
    } else {
      setState(() {
        _templates = [];
      });
    }
  }

  Future<void> _saveTemplates() async {
    if (_currentRequestId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'mqtt_publish_templates_$_currentRequestId',
      jsonEncode(_templates),
    );
  }

  void _saveNewTemplate(String name, String currentPayload) {
    setState(() {
      _templates.insert(0, {'name': name.trim(), 'payload': currentPayload});
    });
    _saveTemplates();
  }

  void _deleteTemplate(int index) {
    setState(() {
      _templates.removeAt(index);
    });
    _saveTemplates();
  }

  void _applyTemplate(Map<String, dynamic> template) {
    final newPayload = template['payload'] ?? '';
    _update((m) => m.copyWith(publishPayload: newPayload));
  }

  void _openTemplatesPanel(
    BuildContext ctx,
    String currentPayload, {
    bool initialIsSavingView = false,
  }) {
    showDialog(
      context: ctx,
      barrierColor: Theme.of(ctx).colorScheme.scrim.withValues(alpha: 0.5),
      builder: (context) {
        return WebSocketTemplatePanel(
          templates: _templates,
          initialIsSavingView: initialIsSavingView,
          currentPayload: currentPayload,
          onClose: () => Navigator.of(context).pop(),
          onSave: (name) {
            _saveNewTemplate(name, currentPayload);
            Navigator.of(context).pop();
          },
          onDelete: _deleteTemplate,
          onSelect: (t) {
            _applyTemplate(t);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _update(MQTTRequestModel Function(MQTTRequestModel) fn) {
    final updated = fn(ref.read(mqttRequestProvider));
    ref.read(mqttRequestProvider.notifier).state = updated;

    final selectedId = ref.read(selectedIdStateProvider);
    if (selectedId != null) {
      ref
          .read(collectionStateNotifierProvider.notifier)
          .updateMQTTState(id: selectedId, mqttRequestModel: updated);
    }
  }

  Future<void> _publish() async {
    final model = ref.read(mqttRequestProvider);
    await ref
        .read(mqttServiceProvider)
        .publish(
          model.publishTopic,
          model.publishPayload,
          qos: model.publishQos,
          retain: model.publishRetain,
        );
  }

  void _addTopic() {
    _update((m) => m.copyWith(topics: [...m.topics, kMQTTTopicEmptyModel]));
  }

  void _deleteTopic(int index) {
    _update((m) {
      final list = List<MQTTTopicModel>.from(m.topics);
      final topic = list[index];

      if (topic.subscribe && topic.topic.isNotEmpty) {
        ref.read(mqttServiceProvider).unsubscribe(topic.topic);
      }

      list.removeAt(index);
      return m.copyWith(topics: list);
    });
  }

  void _updateTopic(int index, MQTTTopicModel updated) {
    _update((m) {
      final list = List<MQTTTopicModel>.from(m.topics);
      if (index >= list.length) {
        final newTopic = updated.copyWith(subscribe: true);
        list.add(newTopic);
        if (newTopic.topic.isNotEmpty) {
          ref.read(mqttServiceProvider).subscribe(newTopic.topic, newTopic.qos);
        }
        return m.copyWith(topics: list);
      }
      final old = list[index];

      if (old.subscribe != updated.subscribe ||
          (updated.subscribe &&
              (old.topic != updated.topic || old.qos != updated.qos))) {
        if (old.subscribe && old.topic.isNotEmpty) {
          ref.read(mqttServiceProvider).unsubscribe(old.topic);
        }
        if (updated.subscribe && updated.topic.isNotEmpty) {
          ref.read(mqttServiceProvider).subscribe(updated.topic, updated.qos);
        }
      }

      list[index] = updated;
      return m.copyWith(topics: list);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedIdStateProvider);
    if (selectedId != null) {
      _checkRequestId(selectedId);
    }
    final connState = ref.watch(mqttConnectionStateProvider).value;
    final isConnected = connState?.isConnected ?? false;
    final topics = ref.watch(mqttTopicsProvider);
    final model = ref.watch(mqttRequestProvider);

    final clrScheme = Theme.of(context).colorScheme;

    final fieldDeco = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      hintStyle: TextStyle(color: clrScheme.outlineVariant),
      focusedBorder: OutlineInputBorder(
        borderRadius: kBorderRadius8,
        borderSide: BorderSide(color: clrScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: kBorderRadius8,
        borderSide: BorderSide(color: clrScheme.surfaceContainerHighest),
      ),
      border: OutlineInputBorder(
        borderRadius: kBorderRadius8,
        borderSide: BorderSide(color: clrScheme.surfaceContainerHighest),
      ),
      filled: true,
      fillColor: clrScheme.surfaceContainerLowest,
      hoverColor: kColorTransparent,
      isDense: true,
    );

    final codePaneVisible = ref.watch(codePaneVisibleStateProvider);

    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.showViewCodeButton
              ? Padding(
                  padding: kP8,
                  child: SizedBox(
                    height: kHeaderHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            padding: kPh12,
                            minimumSize: const Size(44, 44),
                          ),
                          onPressed: () {
                            ref
                                .read(codePaneVisibleStateProvider.notifier)
                                .state = !codePaneVisible;
                          },
                          icon: Icon(
                            codePaneVisible
                                ? Icons.code_off_rounded
                                : Icons.code_rounded,
                            size: 18,
                          ),
                          label: SizedBox(
                            width: 80,
                            child: Text(
                              codePaneVisible ? kLabelHideCode : kLabelViewCode,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : kVSpacer10,
          const TabBar(
            tabs: [
              Tab(text: 'Topics'),
              Tab(text: 'Publish'),
              Tab(text: 'Last Will'),
              Tab(text: 'Config'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TopicsTab(
                  topics: topics,
                  isConnected: isConnected,
                  onAdd: _addTopic,
                  onDelete: _deleteTopic,
                  onUpdate: _updateTopic,
                  mqttService: ref.read(mqttServiceProvider),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: kHeaderHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(kLabelSelectContentType),
                          kHSpacer8,
                          ADDropdownButton<String>(
                            value: _publishContentType,
                            values: const [('json', 'json'), ('text', 'text')],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _publishContentType = v;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 5.0,
                        left: 10.0,
                        right: 10.0,
                      ),
                      child: TextFormField(
                        controller: _publishTopicCtrl,
                        decoration: fieldDeco.copyWith(
                          hintText: 'Topic (e.g. apidash/tele)',
                        ),
                        onChanged: (v) =>
                            _update((m) => m.copyWith(publishTopic: v)),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: kPt5o10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            border:
                                _publishContentType == 'json' &&
                                    !_isValidJson &&
                                    model.publishPayload.trim().isNotEmpty
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.error,
                                  )
                                : null,
                            borderRadius: kBorderRadius8,
                          ),
                          child: _publishContentType == 'json'
                              ? JsonTextFieldEditor(
                                  key: Key("mqtt-json-body-${selectedId}"),
                                  fieldKey: "mqtt-json-body-editor",
                                  isDark:
                                      Theme.of(context).brightness ==
                                      Brightness.dark,
                                  initialValue: model.publishPayload,
                                  onChanged: (String value) {
                                    _update(
                                      (m) => m.copyWith(publishPayload: value),
                                    );
                                    _validateJson(value);
                                  },
                                )
                              : TextFieldEditor(
                                  key: Key("mqtt-text-body-${selectedId}"),
                                  fieldKey: "mqtt-text-body-editor",
                                  initialValue: model.publishPayload,
                                  onChanged: (String value) {
                                    _update(
                                      (m) => m.copyWith(publishPayload: value),
                                    );
                                    _validateJson(value);
                                  },
                                ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 4,
                        bottom: 8,
                        left: 10,
                        right: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            model.publishPayload.trim().isEmpty ||
                                    _publishContentType != 'json'
                                ? Icons.check_circle
                                : (_isValidJson
                                      ? Icons.check_circle
                                      : Icons.cancel),
                            size: 14,
                            color:
                                model.publishPayload.trim().isEmpty ||
                                    _publishContentType != 'json'
                                ? Theme.of(context).colorScheme.outline
                                : (_isValidJson
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.error),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _publishContentType != 'json'
                                  ? 'Text payload'
                                  : (model.publishPayload.trim().isEmpty
                                        ? 'Enter JSON payload'
                                        : (_isValidJson
                                              ? 'Valid JSON'
                                              : 'Invalid JSON: ${_jsonError ?? ''}')),
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    model.publishPayload.trim().isEmpty ||
                                        _publishContentType != 'json'
                                    ? Theme.of(context).colorScheme.outline
                                    : (_isValidJson
                                          ? Colors.green
                                          : Theme.of(
                                              context,
                                            ).colorScheme.error),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 10,
                        right: 10,
                        bottom: 10,
                      ),
                      child: Row(
                        children: [
                          const Text('QoS: '),
                          ADDropdownButton<int>(
                            value: model.publishQos,
                            values: const [(0, '0'), (1, '1'), (2, '2')],
                            onChanged: (int? v) {
                              if (v != null) {
                                _update((m) => m.copyWith(publishQos: v));
                              }
                            },
                          ),
                          kHSpacer8,
                          const Text('Retain: '),
                          Switch(
                            value: model.publishRetain,
                            onChanged: (v) =>
                                _update((m) => m.copyWith(publishRetain: v)),
                            activeThumbColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 40,
                            child: FilledButton.icon(
                              onPressed: () => _openTemplatesPanel(
                                context,
                                model.publishPayload,
                                initialIsSavingView: false,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: kBorderRadius8,
                                ),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.5),
                                ),
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                textStyle: const TextStyle(fontSize: 14),
                              ),
                              icon: Icon(
                                Icons.library_books_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              label: const Text('Templates'),
                            ),
                          ),
                          kHSpacer8,
                          SizedBox(
                            height: 40,
                            child: FilledButton.icon(
                              onPressed:
                                  (isConnected &&
                                      !(_publishContentType == 'json' &&
                                          !_isValidJson))
                                  ? _publish
                                  : null,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: kBorderRadius8,
                                ),
                                textStyle: const TextStyle(fontSize: 14),
                              ),
                              icon: const Icon(Icons.send, size: 16),
                              label: const Text('Publish'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: kPt5o10,
                  child: ListView(
                    children: [
                      Text(
                        'Last Will Topic',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: isConnected
                                  ? Theme.of(context).disabledColor
                                  : null,
                            ),
                      ),
                      kVSpacer8,
                      TextFormField(
                        controller: _lastWillTopicCtrl,
                        enabled: !isConnected,
                        decoration: fieldDeco.copyWith(
                          hintText: 'e.g. client/disconnected',
                        ),
                        onChanged: (v) =>
                            _update((m) => m.copyWith(lastWillTopic: v)),
                      ),
                      kVSpacer16,
                      Text(
                        'Last Will Message',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: isConnected
                                  ? Theme.of(context).disabledColor
                                  : null,
                            ),
                      ),
                      kVSpacer8,
                      TextFormField(
                        controller: _lastWillMessageCtrl,
                        enabled: !isConnected,
                        maxLines: 4,
                        decoration: fieldDeco.copyWith(
                          hintText: 'Offline payload...',
                        ),
                        onChanged: (v) =>
                            _update((m) => m.copyWith(lastWillMessage: v)),
                      ),
                      kVSpacer16,
                      Row(
                        children: [
                          Text(
                            'Last Will QoS: ',
                            style: TextStyle(
                              color: isConnected
                                  ? Theme.of(context).disabledColor
                                  : null,
                            ),
                          ),
                          kHSpacer8,
                          ADDropdownButton<int>(
                            value: model.lastWillQos,
                            values: const [(0, '0'), (1, '1'), (2, '2')],
                            onChanged: !isConnected
                                ? (v) {
                                    if (v != null) {
                                      _update(
                                        (m) => m.copyWith(lastWillQos: v),
                                      );
                                    }
                                  }
                                : null,
                          ),
                          const Spacer(),
                          Text(
                            'Retain Last Will: ',
                            style: TextStyle(
                              color: isConnected
                                  ? Theme.of(context).disabledColor
                                  : null,
                            ),
                          ),
                          Switch(
                            value: model.lastWillRetain,
                            onChanged: !isConnected
                                ? (v) => _update(
                                    (m) => m.copyWith(lastWillRetain: v),
                                  )
                                : null,
                            activeThumbColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: kPt5o10,
                  child: ListView(
                    children: [
                      _ConfigRow(
                        label: 'Client ID',
                        controller: _clientIdCtrl,
                        enabled: !isConnected,
                        hint: 'apidash_client',
                        onChanged: (v) =>
                            _update((m) => m.copyWith(clientId: v)),
                        fieldDeco: fieldDeco,
                      ),
                      _ConfigRow(
                        label: 'Username',
                        controller: _userCtrl,
                        enabled: !isConnected,
                        hint: 'Optional',
                        onChanged: (v) =>
                            _update((m) => m.copyWith(username: v)),
                        fieldDeco: fieldDeco,
                      ),
                      _ConfigRow(
                        label: 'Password',
                        controller: _passCtrl,
                        enabled: !isConnected,
                        hint: 'Optional',
                        obscure: true,
                        onChanged: (v) =>
                            _update((m) => m.copyWith(password: v)),
                        fieldDeco: fieldDeco,
                      ),
                      _ConfigRowInt(
                        label: 'Keep Alive (s)',
                        value: model.keepAlive,
                        enabled: !isConnected,
                        onChanged: (v) =>
                            _update((m) => m.copyWith(keepAlive: v)),
                        fieldDeco: fieldDeco,
                      ),
                      _ConfigRowInt(
                        label: 'Connect Timeout (s)',
                        value: model.connectTimeout,
                        enabled: !isConnected,
                        onChanged: (v) =>
                            _update((m) => m.copyWith(connectTimeout: v)),
                        fieldDeco: fieldDeco,
                      ),
                      SwitchListTile(
                        title: const Text(
                          'Auto Reconnect',
                          style: TextStyle(fontSize: 13),
                        ),
                        contentPadding: EdgeInsets.zero,
                        value: model.autoReconnect,
                        onChanged: isConnected
                            ? null
                            : (v) =>
                                  _update((m) => m.copyWith(autoReconnect: v)),
                      ),
                      SwitchListTile(
                        title: const Text(
                          'Clean Session',
                          style: TextStyle(fontSize: 13),
                        ),
                        contentPadding: EdgeInsets.zero,
                        value: model.cleanSession,
                        onChanged: isConnected
                            ? null
                            : (v) =>
                                  _update((m) => m.copyWith(cleanSession: v)),
                      ),
                      SwitchListTile(
                        title: const Text(
                          'Use TLS (Secure)',
                          style: TextStyle(fontSize: 13),
                        ),
                        contentPadding: EdgeInsets.zero,
                        value: model.useTls,
                        onChanged: isConnected
                            ? null
                            : (v) => _update((m) => m.copyWith(useTls: v)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicsTab extends StatelessWidget {
  final List<MQTTTopicModel> topics;
  final bool isConnected;
  final VoidCallback onAdd;
  final void Function(int) onDelete;
  final void Function(int, MQTTTopicModel) onUpdate;
  final dynamic mqttService;

  const _TopicsTab({
    required this.topics,
    required this.isConnected,
    required this.onAdd,
    required this.onDelete,
    required this.onUpdate,
    required this.mqttService,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kP12,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: kBorderRadius12,
            ),
            margin: kP5,
            child: Theme(
              data: Theme.of(context).copyWith(
                scrollbarTheme: kDataTableScrollbarTheme,
                iconTheme: Theme.of(context).iconTheme.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              child: DataTable2(
                columnSpacing: 12,
                dividerThickness: 0,
                horizontalMargin: 0,
                headingRowHeight: kDataTableRowHeight,
                dataRowHeight: kDataTableRowHeight,
                bottomMargin: kDataTableBottomPadding,
                isVerticalScrollBarVisible: true,
                columns: const [
                  DataColumn2(
                    label: Text(
                      'Topic',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn2(
                    label: Text(
                      'QoS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    fixedWidth: 60,
                  ),
                  DataColumn2(
                    label: Text(
                      'Subscribe',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    fixedWidth: 80,
                  ),
                  DataColumn2(
                    label: Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn2(label: Text(''), fixedWidth: 36),
                ],
                rows: List.generate(topics.length + 1, (i) {
                  bool isLast = i == topics.length;
                  final t = isLast ? kMQTTTopicEmptyModel : topics[i];
                  return DataRow(
                    cells: [
                      DataCell(
                        MqttTopicAutocomplete(
                          keyId: "mqtt-topic-$i",
                          initialValue: t.topic,
                          hintText: 'home/sensor',
                          onChanged: (v) => onUpdate(i, t.copyWith(topic: v)),
                          suffixIcon: Tooltip(
                            message:
                                'Wildcards:\n+ : Single level (e.g. home/+/temp)\n# : Multi level (e.g. home/#)',
                            child: Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        ADDropdownButton<int>(
                          value: t.qos,
                          values: const [(0, '0'), (1, '1'), (2, '2')],
                          onChanged: (v) {
                            if (v != null) {
                              onUpdate(i, t.copyWith(qos: v));
                            }
                          },
                        ),
                      ),
                      DataCell(
                        Switch(
                          value: t.subscribe,
                          onChanged: isLast
                              ? null
                              : (v) => onUpdate(i, t.copyWith(subscribe: v)),
                          activeThumbColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                      ),
                      DataCell(
                        CellField(
                          keyId: "mqtt-desc-$i",
                          initialValue: t.description,
                          hintText: 'Add description',
                          onChanged: (v) =>
                              onUpdate(i, t.copyWith(description: v)),
                        ),
                      ),
                      DataCell(
                        InkWell(
                          onTap: isLast ? null : () => onDelete(i),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              hoverColor: kColorTransparent,
                              splashColor: kColorTransparent,
                              highlightColor: kColorTransparent,
                            ),
                            child: Icon(
                              Icons.remove_circle,
                              size: 16,
                              color: isLast
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: kPb15,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Topic', style: kTextStyleButton),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final bool obscure;
  final void Function(String) onChanged;
  final InputDecoration fieldDeco;

  const _ConfigRow({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.hint,
    required this.onChanged,
    required this.fieldDeco,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: enabled ? null : Theme.of(context).disabledColor,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              obscureText: obscure,
              decoration: fieldDeco.copyWith(hintText: hint),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigRowInt extends StatelessWidget {
  final String label;
  final int value;
  final bool enabled;
  final void Function(int) onChanged;
  final InputDecoration fieldDeco;

  const _ConfigRowInt({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.fieldDeco,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: enabled ? null : Theme.of(context).disabledColor,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: value.toString(),
              enabled: enabled,
              keyboardType: TextInputType.number,
              decoration: fieldDeco,
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null) onChanged(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}
