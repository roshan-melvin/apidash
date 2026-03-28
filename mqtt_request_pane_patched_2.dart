import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/consts.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/models/mqtt_request_model.dart';
import 'package:apidash/widgets/widgets.dart';
import 'package:apidash_core/apidash_core.dart';

class EditMQTTRequestPane extends ConsumerStatefulWidget {
  const EditMQTTRequestPane({super.key});

  @override
  ConsumerState<EditMQTTRequestPane> createState() =>
      _EditMQTTRequestPaneState();
}

class _EditMQTTRequestPaneState extends ConsumerState<EditMQTTRequestPane> {
  // Text controllers for connection config fields
  late final TextEditingController _clientIdCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _publishTopicCtrl;
  late final TextEditingController _publishPayloadCtrl;
  String _publishContentType = 'json';

  @override
  void initState() {
    super.initState();
    final m = ref.read(mqttRequestProvider);
    _clientIdCtrl = TextEditingController(text: m.clientId);
    _userCtrl = TextEditingController(text: m.username);
    _passCtrl = TextEditingController(text: m.password);
    _publishTopicCtrl = TextEditingController(text: m.publishTopic);
    _publishPayloadCtrl = TextEditingController(text: m.publishPayload);
  }

  @override
  void dispose() {
    for (final c in [
      _clientIdCtrl,
      _userCtrl,
      _passCtrl,
      _publishTopicCtrl,
      _publishPayloadCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _update(MQTTRequestModel Function(MQTTRequestModel) fn) {
    final updated = fn(ref.read(mqttRequestProvider));
    ref.read(mqttRequestProvider.notifier).state = updated;

    // Also save to global persistent collection
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
        // also call subscribe since we toggle to true
        if (newTopic.topic.isNotEmpty) {
          ref.read(mqttServiceProvider).subscribe(newTopic.topic, newTopic.qos);
        }
        return m.copyWith(topics: list);
      }
      final old = list[index];

      // If the subscription state toggled, or the topic string/QoS changed while subscribed
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

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(mqttConnectionStateProvider).value;
    final isConnected = connState?.isConnected ?? false;
    final topics = ref.watch(mqttTopicsProvider);
    final model = ref.watch(mqttRequestProvider);

    final clrScheme = Theme.of(context).colorScheme;

    final fieldDeco = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      border: OutlineInputBorder(
        borderRadius: kBorderRadius8,
        borderSide: BorderSide(color: clrScheme.outlineVariant),
      ),
      isDense: true,
    );

    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tabs ──────────────────────────────────────────────────────
          const TabBar(
            tabs: [
              Tab(text: 'Topics'),
              Tab(text: 'Publish'),
              Tab(text: 'Config'),
              Tab(text: 'Last Will'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // ── Topics Tab ───────────────────────────────────────────
                _TopicsTab(
                  topics: topics,
                  isConnected: isConnected,
                  onAdd: _addTopic,
                  onDelete: _deleteTopic,
                  onUpdate: _updateTopic,
                  mqttService: ref.read(mqttServiceProvider),
                ),
                // ── Publish Tab ──────────────────────────────────────────
                Padding(
                  padding: kPh8v4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Publish Message',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: 'JSON',
                              items: ['JSON', 'Text']
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {},
                            ),
                          ),
                        ],
                      ),
                      kVSpacer8,
                      TextFormField(
                        controller: _publishTopicCtrl,
                        decoration: fieldDeco.copyWith(
                          hintText: 'Topic (e.g. apidash/tele)',
                        ),
                        onChanged: (v) =>
                            _update((m) => m.copyWith(publishTopic: v)),
                      ),
                      kVSpacer10,
                      Expanded(
                        child: TextFormField(
                          controller: _publishPayloadCtrl,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          decoration: fieldDeco.copyWith(
                            hintText: 'Payload\n{\n  "status": "active"\n}',
                          ),
                          onChanged: (v) =>
                              _update((m) => m.copyWith(publishPayload: v)),
                        ),
                      ),
                      kVSpacer8,
                      Row(
                        children: [
                          const Text('QoS: '),
                          kHSpacer8,
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 0, label: Text('0')),
                              ButtonSegment(value: 1, label: Text('1')),
                              ButtonSegment(value: 2, label: Text('2')),
                            ],
                            selected: {model.publishQos},
                            onSelectionChanged: (Set<int> newSelection) =>
                                _update(
                                  (m) => m.copyWith(
                                    publishQos: newSelection.first,
                                  ),
                                ),
                          ),
                          const Spacer(),
                          const Text('Retain: '),
                          Switch(
                            value: model.publishRetain,
                            onChanged: (v) =>
                                _update((m) => m.copyWith(publishRetain: v)),
                          ),
                          kHSpacer12,
                          FilledButton.icon(
                            onPressed: isConnected ? _publish : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: kBorderRadius8,
                              ),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: const Text('Publish'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ── Config Tab ───────────────────────────────────────────
                Padding(
                  padding: kPh8v4,
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
                      ),
                      _ConfigRowInt(
                        label: 'Connect Timeout (s)',
                        value: model.connectTimeout,
                        enabled: !isConnected,
                        onChanged: (v) =>
                            _update((m) => m.copyWith(connectTimeout: v)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 150,
                              child: Text(
                                'Protocol Version',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child:
                                  DropdownButtonFormField<MQTTProtocolVersion>(
                                    initialValue: model.protocolVersion,
                                    isDense: true,
                                    decoration: fieldDeco,
                                    items: MQTTProtocolVersion.values.map((v) {
                                      return DropdownMenuItem(
                                        value: v,
                                        child: Text(v.name.toUpperCase()),
                                      );
                                    }).toList(),
                                    onChanged: isConnected
                                        ? null
                                        : (v) {
                                            if (v != null)
                                              _update(
                                                (m) => m.copyWith(
                                                  protocolVersion: v,
                                                ),
                                              );
                                          },
                                  ),
                            ),
                          ],
                        ),
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
                // ── Last Will Tab ─────────────────────────────────────────
                Padding(
                  padding: kPh8v4,
                  child: ListView(
                    children: [
                      Text(
                        'Last Will Topic',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      kVSpacer8,
                      TextFormField(
                        enabled: !isConnected,
                        decoration: fieldDeco.copyWith(
                          hintText: 'e.g. client/disconnected',
                        ),
                      ),
                      kVSpacer16,
                      Text(
                        'Last Will Message',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      kVSpacer8,
                      TextFormField(
                        enabled: !isConnected,
                        maxLines: 4,
                        decoration: fieldDeco.copyWith(
                          hintText: 'Offline payload...',
                        ),
                      ),
                      kVSpacer16,
                      Row(
                        children: [
                          const Text('Last Will QoS: '),
                          kHSpacer8,
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 0, label: Text('0')),
                              ButtonSegment(value: 1, label: Text('1')),
                              ButtonSegment(value: 2, label: Text('2')),
                            ],
                            selected: {0},
                            onSelectionChanged: !isConnected ? (s) {} : null,
                          ),
                          const Spacer(),
                          const Text('Retain Last Will: '),
                          Switch(
                            value: false,
                            onChanged: !isConnected ? (v) {} : null,
                          ),
                        ],
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

// ── Topic Table ───────────────────────────────────────────────────────────────

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
                  DataColumn2(label: Text(kNameCheckbox), fixedWidth: 30),
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
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn2(label: const Text(''), fixedWidth: 36),
                ],
                rows: List.generate(topics.length + 1, (i) {
                  bool isLast = i == topics.length;
                  final t = isLast ? kMQTTTopicEmptyModel : topics[i];
                  return DataRow(
                    cells: [
                      DataCell(
                        ADCheckBox(
                          keyId: "mqtt-topic-sub-$i",
                          value: t.subscribe,
                          onChanged: isLast
                              ? null
                              : (v) => onUpdate(
                                  i,
                                  t.copyWith(subscribe: v ?? false),
                                ),
                          colorScheme: Theme.of(context).colorScheme,
                        ),
                      ),
                      DataCell(
                        TextFormField(
                          initialValue: t.topic,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'home/sensor',
                          ),
                          onChanged: (v) => onUpdate(i, t.copyWith(topic: v)),
                        ),
                      ),
                      DataCell(
                        DropdownButton<int>(
                          value: t.qos,
                          underline: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('0')),
                            DropdownMenuItem(value: 1, child: Text('1')),
                            DropdownMenuItem(value: 2, child: Text('2')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              onUpdate(i, t.copyWith(qos: v));
                            }
                          },
                        ),
                      ),
                      DataCell(
                        TextFormField(
                          initialValue: t.description,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Add description',
                          ),
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
                icon: Icon(Icons.add),
                label: const Text('Add Topic', style: kTextStyleButton),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Config helpers ────────────────────────────────────────────────────────────

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
            child: Text(label, style: const TextStyle(fontSize: 13)),
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

  const _ConfigRowInt({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: value.toString(),
              enabled: enabled,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
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
