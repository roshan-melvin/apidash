import 'package:data_table_2/data_table_2.dart';
import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/services/mqtt_service.dart';

final _timeFmt = DateFormat('HH:mm:ss.SSS');

/// The right‑hand pane shown when API type is MQTT.
/// Displays a real‑time message feed and a filterable event log.
class MQTTResponsePane extends ConsumerStatefulWidget {
  const MQTTResponsePane({super.key});

  @override
  ConsumerState<MQTTResponsePane> createState() => _MQTTResponsePaneState();
}

class _MQTTResponsePaneState extends ConsumerState<MQTTResponsePane>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _filterTopic = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Activate the sync listener — ensures messages/events auto-save to Hive
    ref.watch(mqttStateSyncProvider);
    final messages = ref.watch(mqttMessagesProvider);
    final events = ref.watch(mqttEventLogProvider);
    final connState = ref.watch(mqttConnectionStateProvider).value;
    final isConnected = connState?.isConnected ?? false;

    final inCount = messages.where((m) => m.isIncoming).length;
    final outCount = messages.where((m) => !m.isIncoming).length;

    // Filter messages by topic if a filter is set
    final filtered = _filterTopic.isEmpty
        ? messages
        : messages.where((m) => m.topic.contains(_filterTopic)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Status bar ──────────────────────────────────────────────────
        _StatusBar(
          isConnected: isConnected,
          error: connState?.error,
          inCount: inCount,
          outCount: outCount,
        ),
        // ── Tabs ────────────────────────────────────────────────────────
        TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Messages'),
                  kHSpacer8,
                  if (messages.isNotEmpty) _Badge(count: messages.length),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Events'),
                  kHSpacer8,
                  if (events.isNotEmpty) _Badge(count: events.length),
                ],
              ),
            ),
          ],
        ),
        // ── Topic filter (Messages tab only) ────────────────────────────
        AnimatedBuilder(
          animation: _tabCtrl,
          builder: (_, __) => _tabCtrl.index == 0
              ? Padding(
                  padding: kPh8v4,
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Filter by topic…',
                      prefixIcon: const Icon(
                        Icons.filter_list_rounded,
                        size: 18,
                      ),
                      border: OutlineInputBorder(borderRadius: kBorderRadius8),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                    ),
                    onChanged: (v) => setState(() => _filterTopic = v),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // ── Tab content ─────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              // Messages feed
              filtered.isEmpty
                  ? _EmptyState(
                      icon: Icons.inbox_rounded,
                      label: isConnected
                          ? 'Waiting for messages…'
                          : 'Connect to start receiving',
                    )
                  : _MessageList(messages: filtered),
              // Event log
              events.isEmpty
                  ? const _EmptyState(
                      icon: Icons.article_outlined,
                      label: 'No events yet',
                    )
                  : _EventList(events: events),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  final bool isConnected;
  final String? error;
  final int inCount;
  final int outCount;

  const _StatusBar({
    required this.isConnected,
    this.error,
    required this.inCount,
    required this.outCount,
  });

  @override
  Widget build(BuildContext context) {
    final clrScheme = Theme.of(context).colorScheme;

    if (error != null) {
      return Container(
        color: clrScheme.errorContainer,
        width: double.infinity,
        padding: kP8,
        child: Row(
          children: [
            Icon(Icons.error, color: clrScheme.error, size: 18),
            kHSpacer8,
            Expanded(
              child: Text(
                error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: clrScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: kP8,
      decoration: BoxDecoration(
        color: clrScheme.surfaceContainerHighest.withAlpha(50),
        border: Border(bottom: BorderSide(color: clrScheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
              ),
              kHSpacer8,
              Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_downward,
                    size: 14,
                    color: clrScheme.primary,
                  ),
                  kHSpacer4,
                  Text('Rx: $inCount'),
                  const SizedBox(width: 16),
                  Icon(Icons.arrow_upward, size: 14, color: clrScheme.primary),
                  kHSpacer4,
                  Text('Tx: $outCount'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message List ──────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final List<MQTTMessage> messages;

  const _MessageList({required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const Center(child: Text('No messages yet.'));

    final reversed = messages.reversed.toList();
    return ListView.separated(
      padding: kP12,
      itemCount: reversed.length,
      separatorBuilder: (_, __) => kVSpacer8,
      itemBuilder: (ctx, idx) {
        final m = reversed[idx];
        return _MessageTile(message: m);
      },
    );
  }
}

class _MessageTile extends StatelessWidget {
  final MQTTMessage message;

  const _MessageTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final bg = message.isIncoming
        ? clr.secondaryContainer.withAlpha(150)
        : clr.primaryContainer.withAlpha(150);
    final borderClr = message.isIncoming ? clr.secondary : clr.primary;
    final icon = message.isIncoming ? Icons.arrow_downward : Icons.arrow_upward;
    final label = message.isIncoming ? 'IN' : 'OUT';

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: kBorderRadius8,
        border: Border.all(color: borderClr.withAlpha(50)),
      ),
      padding: kP8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: borderClr.withAlpha(200),
                  borderRadius: kBorderRadius4,
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 10, color: clr.onPrimary),
                    kHSpacer4,
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: clr.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              kHSpacer8,
              Expanded(
                child: Text(
                  message.topic,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Text(
                _timeFmt.format(message.timestamp),
                style: TextStyle(fontSize: 10, color: clr.outline),
              ),
            ],
          ),
          kVSpacer8,
          SelectableText(
            message.payload.isEmpty ? '(empty)' : message.payload,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Event Log ─────────────────────────────────────────────────────────────────

class _EventList extends StatelessWidget {
  final List<MQTTEvent> events;

  const _EventList({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const Center(child: Text('No events.'));

    final clr = Theme.of(context).colorScheme;
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      headingRowHeight: 0,
      columns: const [
        DataColumn2(label: Text(''), fixedWidth: 100),
        DataColumn2(label: Text(''), fixedWidth: 100),
        DataColumn2(label: Text('')),
      ],
      rows: events.reversed.map((e) {
        return DataRow(
          cells: [
            DataCell(
              Text(
                _timeFmt.format(e.timestamp),
                style: TextStyle(color: clr.outline, fontSize: 12),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: clr.surfaceContainerHighest,
                  borderRadius: kBorderRadius4,
                ),
                child: Text(
                  e.type.name.toUpperCase(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(e.description, style: const TextStyle(fontSize: 12)),
                  if (e.topic != null)
                    Text(
                      e.topic!,
                      style: TextStyle(
                        fontSize: 11,
                        color: clr.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
          kVSpacer8,
          Text(
            label,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
