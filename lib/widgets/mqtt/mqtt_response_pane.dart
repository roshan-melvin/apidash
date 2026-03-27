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
  ConsumerState<MQTTResponsePane> createState() =>
      _MQTTResponsePaneState();
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
    final connState =
        ref.watch(mqttConnectionStateProvider).value;
    final isConnected = connState?.isConnected ?? false;

    final inCount = messages.where((m) => m.isIncoming).length;
    final outCount = messages.where((m) => !m.isIncoming).length;

    // Filter messages by topic if a filter is set
    final filtered = _filterTopic.isEmpty
        ? messages
        : messages
            .where((m) => m.topic.contains(_filterTopic))
            .toList();

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
                  if (messages.isNotEmpty)
                    _Badge(count: messages.length),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Events'),
                  kHSpacer8,
                  if (events.isNotEmpty)
                    _Badge(count: events.length),
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
                      prefixIcon:
                          const Icon(Icons.filter_list_rounded, size: 18),
                      border: OutlineInputBorder(
                          borderRadius: kBorderRadius8),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                    ),
                    onChanged: (v) =>
                        setState(() => _filterTopic = v),
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
    this.inCount = 0,
    this.outCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isConnected
          ? const Color(0xFF8B5CF6).withOpacity(0.08)
          : clr.surfaceContainerHighest.withOpacity(0.4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.greenAccent : clr.outline,
            ),
          ),
          kHSpacer8,
          Expanded(
            child: Tooltip(
              message: isConnected ? 'Connected' : (error ?? 'Disconnected'),
              child: Text(
                isConnected ? 'Connected' : (error ?? 'Disconnected'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isConnected
                      ? Colors.greenAccent
                      : (error != null ? clr.error : clr.outline),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (isConnected) ...[
            const Icon(Icons.download_rounded, size: 14, color: Color(0xFF8B5CF6)),
            kHSpacer4,
            Text('Rx: $inCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            kHSpacer10,
            const Icon(Icons.upload_rounded, size: 14, color: Colors.cyanAccent),
            kHSpacer4,
            Text('Tx: $outCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ]
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
    // Show newest first
    final reversed = messages.reversed.toList();
    return ListView.separated(
      padding: kPh8v4,
      itemCount: reversed.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final msg = reversed[i];
        return _MessageTile(message: msg);
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
    final isIn = message.isIncoming;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic + direction badge + time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isIn
                      ? const Color(0xFF8B5CF6).withOpacity(0.15)
                      : clr.primaryContainer,
                  borderRadius: kBorderRadius4,
                ),
                child: Text(
                  isIn ? '↓ IN' : '↑ OUT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isIn
                        ? const Color(0xFF8B5CF6)
                        : clr.onPrimaryContainer,
                  ),
                ),
              ),
              kHSpacer8,
              Expanded(
                child: Text(
                  message.topic,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _timeFmt.format(message.timestamp),
                style:
                    TextStyle(fontSize: 11, color: clr.outline),
              ),
            ],
          ),
          kVSpacer4,
          // Payload
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: clr.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: kBorderRadius8,
            ),
            child: SelectableText(
              message.payload.isEmpty ? '(empty)' : message.payload,
              style: const TextStyle(
                  fontSize: 12, fontFamily: 'monospace'),
            ),
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
    final reversed = events.reversed.toList();
    return ListView.builder(
      padding: kPh8v4,
      itemCount: reversed.length,
      itemBuilder: (context, i) {
        final e = reversed[i];
        return _EventTile(event: e);
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  final MQTTEvent event;
  const _EventTile({required this.event});

  static const _typeColors = {
    MQTTEventType.connect: Colors.greenAccent,
    MQTTEventType.disconnect: Colors.redAccent,
    MQTTEventType.subscribe: Colors.blueAccent,
    MQTTEventType.unsubscribe: Colors.grey,
    MQTTEventType.send: Colors.cyanAccent,
    MQTTEventType.receive: Color(0xFF8B5CF6),
    MQTTEventType.error: Colors.redAccent,
  };

  static const _typeIcons = {
    MQTTEventType.connect: Icons.link_rounded,
    MQTTEventType.disconnect: Icons.link_off_rounded,
    MQTTEventType.subscribe: Icons.bookmark_add_rounded,
    MQTTEventType.unsubscribe: Icons.bookmark_remove_rounded,
    MQTTEventType.send: Icons.upload_rounded,
    MQTTEventType.receive: Icons.download_rounded,
    MQTTEventType.error: Icons.error_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final col = _typeColors[event.type] ?? Colors.grey;
    final icon = _typeIcons[event.type] ?? Icons.circle;
    final clr = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: col),
          kHSpacer8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.description,
                  style: const TextStyle(fontSize: 12),
                ),
                if (event.topic != null)
                  Text(
                    event.topic!,
                    style: TextStyle(
                        fontSize: 11,
                        color: clr.outline,
                        fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          Text(
            _timeFmt.format(event.timestamp),
            style: TextStyle(fontSize: 10, color: clr.outline),
          ),
        ],
      ),
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
        color: const Color(0xFF8B5CF6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style:
            const TextStyle(color: Colors.white, fontSize: 10),
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
          Icon(icon, size: 40,
              color: Theme.of(context).colorScheme.outline),
          kVSpacer8,
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}
