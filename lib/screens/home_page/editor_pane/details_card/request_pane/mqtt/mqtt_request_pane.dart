import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/consts.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/models/mqtt_request_model.dart';

class EditMQTTRequestPane extends ConsumerStatefulWidget {
  const EditMQTTRequestPane({super.key});

  @override
  ConsumerState<EditMQTTRequestPane> createState() =>
      _EditMQTTRequestPaneState();
}

class _EditMQTTRequestPaneState
    extends ConsumerState<EditMQTTRequestPane> {
  bool _isConnecting = false;
  // Text controllers for connection config fields
  late final TextEditingController _brokerCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _clientIdCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _publishTopicCtrl;
  late final TextEditingController _publishPayloadCtrl;

  @override
  void initState() {
    super.initState();
    final m = ref.read(mqttRequestProvider);
    _brokerCtrl = TextEditingController(text: m.brokerUrl);
    _portCtrl = TextEditingController(text: m.port.toString());
    _clientIdCtrl = TextEditingController(text: m.clientId);
    _userCtrl = TextEditingController(text: m.username);
    _passCtrl = TextEditingController(text: m.password);
    _publishTopicCtrl = TextEditingController(text: m.publishTopic);
    _publishPayloadCtrl =
        TextEditingController(text: m.publishPayload);
  }

  @override
  void dispose() {
    for (final c in [
      _brokerCtrl,
      _portCtrl,
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
      ref.read(collectionStateNotifierProvider.notifier).updateMQTTState(
        id: selectedId,
        mqttRequestModel: updated,
      );
    }
  }

  Future<void> _connect() async {
    setState(() => _isConnecting = true);
    final mqttService = ref.read(mqttServiceProvider);
    final request = ref.read(mqttRequestProvider);
    await mqttService.connect(request);
    if (mounted) {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnect() async {
    await ref.read(mqttServiceProvider).disconnect();
  }

  Future<void> _publish() async {
    final model = ref.read(mqttRequestProvider);
    await ref.read(mqttServiceProvider).publish(
          model.publishTopic,
          model.publishPayload,
          qos: model.publishQos,
          retain: model.publishRetain,
        );
  }

  void _addTopic() {
    _update((m) => m.copyWith(
          topics: [...m.topics, kMQTTTopicEmptyModel],
        ));
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
      final old = list[index];

      // If the subscription state toggled, or the topic string/QoS changed while subscribed
      if (old.subscribe != updated.subscribe || 
          (updated.subscribe && (old.topic != updated.topic || old.qos != updated.qos))) {
          
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
    final connState =
        ref.watch(mqttConnectionStateProvider).value;
    final isConnected = connState?.isConnected ?? false;
    final isReconnecting = connState?.isReconnecting ?? false;
    final showLoading = _isConnecting || isReconnecting;
    final topics = ref.watch(mqttTopicsProvider);
    final model = ref.watch(mqttRequestProvider);

    ref.listen(mqttRequestProvider, (previous, next) {
      if (previous?.brokerUrl != next.brokerUrl &&
          _brokerCtrl.text != next.brokerUrl) {
        _brokerCtrl.text = next.brokerUrl;
      }
    });

    final clrScheme = Theme.of(context).colorScheme;

    final fieldDeco = InputDecoration(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      border: OutlineInputBorder(
        borderRadius: kBorderRadius8,
        borderSide:
            BorderSide(color: clrScheme.outlineVariant),
      ),
      isDense: true,
    );

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Connection bar ────────────────────────────────────────────
          Padding(
            padding: kPh8v4,
            child: Row(
              children: [
                // Broker URL
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _brokerCtrl,
                    enabled: !isConnected,
                    decoration: fieldDeco.copyWith(
                        hintText: 'broker.hivemq.com'),
                    onChanged: (v) =>
                        _update((m) => m.copyWith(brokerUrl: v)),
                  ),
                ),
                kHSpacer8,
                // Port
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    controller: _portCtrl,
                    enabled: !isConnected,
                    keyboardType: TextInputType.number,
                    decoration:
                        fieldDeco.copyWith(hintText: '1883'),
                    onChanged: (v) => _update((m) =>
                        m.copyWith(port: int.tryParse(v) ?? 1883)),
                  ),
                ),
                kHSpacer8,
                // Connect / Disconnect button
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isConnected
                        ? clrScheme.error
                        : const Color(0xFF8B5CF6),
                    padding: kPh12,
                    minimumSize: const Size(44, 36),
                  ),
                  onPressed: showLoading
                      ? null
                      : (isConnected ? _disconnect : _connect),
                  icon: showLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        )
                      : Icon(
                          isConnected
                              ? Icons.link_off_rounded
                              : Icons.link_rounded,
                          size: 18,
                        ),
                  label: Text(
                      isConnected ? 'Disconnect' : (showLoading ? 'Connecting...' : 'Connect')),
                ),
              ],
            ),
          ),
          // Connection status badge
          if (connState?.error != null)
            Padding(
              padding: kPh8v4,
              child: Text(
                connState!.error!,
                style: TextStyle(
                    color: clrScheme.error, fontSize: 12),
              ),
            ),
          // ── Tabs ──────────────────────────────────────────────────────
          const TabBar(
            tabs: [
              Tab(text: 'Topics'),
              Tab(text: 'Publish'),
              Tab(text: 'Config'),
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text('Topic',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall),
                      kVSpacer4,
                      TextFormField(
                        controller: _publishTopicCtrl,
                        decoration: fieldDeco.copyWith(
                            hintText: 'home/sensor/temp'),
                        onChanged: (v) => _update(
                            (m) => m.copyWith(publishTopic: v)),
                      ),
                      kVSpacer8,
                      Text('Payload',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall),
                      kVSpacer4,
                      TextFormField(
                        controller: _publishPayloadCtrl,
                        maxLines: 4,
                        decoration: fieldDeco.copyWith(
                            hintText: '{"value": 23.5}'),
                        onChanged: (v) => _update((m) =>
                            m.copyWith(publishPayload: v)),
                      ),
                      kVSpacer8,
                      Row(
                        children: [
                          Text('QoS',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall),
                          kHSpacer8,
                          for (int q in [0, 1, 2])
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: 4),
                              child: ChoiceChip(
                                label: Text('$q'),
                                selected: model.publishQos == q,
                                onSelected: (_) => _update((m) =>
                                    m.copyWith(publishQos: q)),
                              ),
                            ),
                          const Spacer(),
                          Row(children: [
                            const Text('Retain'),
                            Switch(
                              value: model.publishRetain,
                              onChanged: (v) => _update((m) =>
                                  m.copyWith(publishRetain: v)),
                            ),
                          ]),
                        ],
                      ),
                      kVSpacer8,
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              isConnected ? _publish : null,
                          icon: const Icon(
                              Icons.send_rounded, size: 18),
                          label: const Text('Publish'),
                        ),
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
                        onChanged: (v) => _update(
                            (m) => m.copyWith(clientId: v)),
                        fieldDeco: fieldDeco,
                      ),
                      _ConfigRow(
                        label: 'Username',
                        controller: _userCtrl,
                        enabled: !isConnected,
                        hint: 'Optional',
                        onChanged: (v) => _update(
                            (m) => m.copyWith(username: v)),
                        fieldDeco: fieldDeco,
                      ),
                      _ConfigRow(
                        label: 'Password',
                        controller: _passCtrl,
                        enabled: !isConnected,
                        hint: 'Optional',
                        obscure: true,
                        onChanged: (v) => _update(
                            (m) => m.copyWith(password: v)),
                        fieldDeco: fieldDeco,
                      ),
                      _ConfigRowInt(
                        label: 'Keep Alive (s)',
                        value: model.keepAlive,
                        enabled: !isConnected,
                        onChanged: (v) => _update(
                            (m) => m.copyWith(keepAlive: v)),
                      ),
                      _ConfigRowInt(
                        label: 'Connect Timeout (s)',
                        value: model.connectTimeout,
                        enabled: !isConnected,
                        onChanged: (v) => _update((m) =>
                            m.copyWith(connectTimeout: v)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 150,
                              child: Text('Protocol Version',
                                  style: TextStyle(fontSize: 13)),
                            ),
                            Expanded(
                              child: DropdownButtonFormField<MQTTProtocolVersion>(
                                value: model.protocolVersion,
                                isDense: true,
                                decoration: fieldDeco,
                                items: MQTTProtocolVersion.values.map((v) {
                                  return DropdownMenuItem(
                                    value: v,
                                    child: Text(v.name.toUpperCase()),
                                  );
                                }).toList(),
                                onChanged: isConnected ? null : (v) {
                                  if (v != null) _update((m) => m.copyWith(protocolVersion: v));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Clean Session', style: TextStyle(fontSize: 13)),
                        contentPadding: EdgeInsets.zero,
                        value: model.cleanSession,
                        onChanged: isConnected
                            ? null
                            : (v) => _update((m) =>
                                m.copyWith(cleanSession: v)),
                      ),
                      SwitchListTile(
                        title: const Text('Use TLS (Secure)', style: TextStyle(fontSize: 13)),
                        contentPadding: EdgeInsets.zero,
                        value: model.useTls,
                        onChanged: isConnected
                            ? null
                            : (v) => _update((m) =>
                                m.copyWith(useTls: v)),
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
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: kPh10t10,
            child: Theme(
              data: Theme.of(context).copyWith(
                  scrollbarTheme: kDataTableScrollbarTheme),
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
                      label: Text('Topic',
                          style: TextStyle(
                              fontWeight: FontWeight.bold))),
                  DataColumn2(
                      label: Text('QoS',
                          style: TextStyle(
                              fontWeight: FontWeight.bold)),
                      fixedWidth: 60),
                  DataColumn2(
                      label: Text('Sub',
                          style: TextStyle(
                              fontWeight: FontWeight.bold)),
                      fixedWidth: 56),
                  DataColumn2(
                      label: Text('Description',
                          style: TextStyle(
                              fontWeight: FontWeight.bold))),
                  DataColumn2(
                      label: const Text(''), fixedWidth: 36),
                ],
                rows: topics.isEmpty
                    ? [
                        const DataRow(cells: [
                          DataCell(
                              Text('No topics — tap Add below')),
                          DataCell.empty,
                          DataCell.empty,
                          DataCell.empty,
                          DataCell.empty,
                        ])
                      ]
                    : List.generate(topics.length, (i) {
                        final t = topics[i];
                        return DataRow(cells: [
                          DataCell(TextFormField(
                            initialValue: t.topic,
                            decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'home/sensor'),
                            onChanged: (v) =>
                                onUpdate(i, t.copyWith(topic: v)),
                          )),
                          DataCell(DropdownButton<int>(
                            value: t.qos,
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(
                                  value: 0,
                                  child: Text('0')),
                              DropdownMenuItem(
                                  value: 1,
                                  child: Text('1')),
                              DropdownMenuItem(
                                  value: 2,
                                  child: Text('2')),
                            ],
                            onChanged: (v) {
                              if (v != null)
                                onUpdate(i, t.copyWith(qos: v));
                            },
                          )),
                          DataCell(Switch(
                            value: t.subscribe,
                            onChanged: (v) =>
                                onUpdate(i, t.copyWith(subscribe: v)),
                          )),
                          DataCell(TextFormField(
                            initialValue: t.description,
                            decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Add description'),
                            onChanged: (v) => onUpdate(
                                i, t.copyWith(description: v)),
                          )),
                          DataCell(IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18),
                            color: Colors.redAccent,
                            onPressed: () => onDelete(i),
                          )),
                        ]);
                      }),
              ),
            ),
          ),
        ),
        Padding(
          padding: kPb15,
          child: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Topic'),
          ),
        ),
      ],
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
            child: Text(label,
                style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              obscureText: obscure,
              decoration:
                  fieldDeco.copyWith(hintText: hint),
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
            child: Text(label,
                style: const TextStyle(fontSize: 13)),
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
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
