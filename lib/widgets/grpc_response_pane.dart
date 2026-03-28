import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/services/grpc_service.dart';

final _timeFmt = DateFormat('HH:mm:ss.SSS');

class GrpcResponsePane extends ConsumerStatefulWidget {
  const GrpcResponsePane({super.key});

  @override
  ConsumerState<GrpcResponsePane> createState() => _GrpcResponsePaneState();
}

class _GrpcResponsePaneState extends ConsumerState<GrpcResponsePane>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _filterString = '';
  String _filterEventString = '';
  int _filterEventIndex = 0;
  late final TextEditingController _msgFilterCtrl;
  late final TextEditingController _eventFilterCtrl;
  int _filterIndex = 0;

  @override
  void initState() {
    super.initState();
    _msgFilterCtrl = TextEditingController(text: _filterString);
    _eventFilterCtrl = TextEditingController(text: _filterEventString);

    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _msgFilterCtrl.dispose();
    _eventFilterCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedIdStateProvider);
    if (selectedId == null) return kSizedBoxEmpty;

    final messages = ref.watch(grpcMessagesProvider(selectedId));
    final events = ref.watch(grpcEventLogProvider(selectedId));
    final connState = ref.watch(grpcStateProvider).value;
    final isConnected = connState?.isConnected ?? false;

    final inCount = messages.where((m) => m.isIncoming).length;
    final outCount = messages.where((m) => !m.isIncoming).length;

    // 0: all, 1: sent, 2: received
    var typeFiltered = messages;
    if (_filterIndex == 1) {
      typeFiltered = messages.where((m) => !m.isIncoming).toList();
    } else if (_filterIndex == 2) {
      typeFiltered = messages.where((m) => m.isIncoming).toList();
    }
    // Local filter state implementation if we want

    var typeFilteredEvents = events;
    if (_filterEventIndex == 1) {
      typeFilteredEvents = events
          .where(
            (e) =>
                e.type == GrpcEventType.error ||
                e.type == GrpcEventType.disconnect,
          )
          .toList();
    } else if (_filterEventIndex == 2) {
      typeFilteredEvents = events
          .where(
            (e) =>
                e.type != GrpcEventType.error &&
                e.type != GrpcEventType.disconnect,
          )
          .toList();
    }

    final filteredEvents = _filterEventString.isEmpty
        ? typeFilteredEvents
        : typeFilteredEvents
              .where(
                (e) => e.description.toLowerCase().contains(
                  _filterEventString.toLowerCase(),
                ),
              )
              .toList();

    final filtered = _filterString.isEmpty
        ? typeFiltered
        : typeFiltered
              .where((m) => m.payload.toString().contains(_filterString))
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusBar(
          isConnected: isConnected,
          error: connState?.error,
          inCount: inCount,
          outCount: outCount,
        ),
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
        IndexedStack(
          index: _tabCtrl.index,
          children: [
            Padding(
              padding: kPh8v4,
              child: Row(
                children: [
                  ADDropdownButton<int>(
                    value: _filterIndex,
                    onChanged: (int? value) {
                      if (value != null) {
                        setState(() {
                          _filterIndex = value;
                        });
                      }
                    },
                    values: const [(0, 'All'), (1, 'Sent'), (2, 'Received')],
                  ),
                  kHSpacer8,
                  Expanded(
                    child: TextField(
                      controller: _msgFilterCtrl,
                      onChanged: (v) => setState(() => _filterString = v),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.light
                            ? Colors.white
                            : null,
                        isDense: true,
                        hintText: 'Filter payload...',
                        prefixIcon: const Icon(Icons.search, size: 16),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        suffixIcon: _msgFilterCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _msgFilterCtrl.clear();
                                  setState(() => _filterString = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: kPh8v4,
              child: Row(
                children: [
                  ADDropdownButton<int>(
                    value: _filterEventIndex,
                    onChanged: (int? value) {
                      if (value != null) {
                        setState(() {
                          _filterEventIndex = value;
                        });
                      }
                    },
                    values: const [(0, 'All'), (1, 'Error'), (2, 'No Error')],
                  ),
                  kHSpacer8,
                  Expanded(
                    child: TextField(
                      controller: _eventFilterCtrl,
                      onChanged: (v) => setState(() => _filterEventString = v),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.light
                            ? Colors.white
                            : null,
                        isDense: true,
                        hintText: 'Filter events...',
                        prefixIcon: const Icon(Icons.search, size: 16),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        suffixIcon: _eventFilterCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _eventFilterCtrl.clear();
                                  setState(() => _filterEventString = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _MessageStream(messages: filtered),
              _EventLog(events: filteredEvents),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.isConnected,
    this.error,
    required this.inCount,
    required this.outCount,
  });

  final bool isConnected;
  final String? error;
  final int inCount;
  final int outCount;

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

class _MessageStream extends StatelessWidget {
  const _MessageStream({required this.messages});
  final List<GrpcMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const Center(child: Text('No messages yet.'));

    return ListView.separated(
      padding: kP12,
      itemCount: messages.length,
      separatorBuilder: (_, _) => kVSpacer8,
      itemBuilder: (ctx, idx) {
        final m = messages[idx];
        return _MessageBubble(msg: m);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final GrpcMessage msg;

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final isIncoming = msg.isIncoming;
    final bg = isIncoming ? clr.secondaryContainer : clr.primaryContainer;
    final borderClr = isIncoming ? clr.secondary : clr.primary;
    final icon = isIncoming ? Icons.arrow_downward : Icons.arrow_upward;
    final label = isIncoming ? 'IN' : 'OUT';

    return Align(
      alignment: isIncoming ? Alignment.centerLeft : Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: 0.8,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isIncoming ? 0 : 12),
              bottomRight: Radius.circular(isIncoming ? 12 : 0),
            ),
            border: Border.all(color: borderClr.withAlpha(50)),
          ),
          padding: kP8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
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
                  const Spacer(),
                  Text(
                    _timeFmt.format(msg.timestamp),
                    style: TextStyle(fontSize: 11, color: clr.onSurfaceVariant),
                  ),
                ],
              ),
              kVSpacer8,
              SelectableText(
                msg.payload,
                style: TextStyle(color: clr.onSurface, fontFamily: 'Courier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventLog extends StatelessWidget {
  const _EventLog({required this.events});
  final List<GrpcEvent> events;

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
                  color:
                      (e.type == GrpcEventType.error ||
                          e.type == GrpcEventType.disconnect)
                      ? clr.errorContainer
                      : (e.type == GrpcEventType.connect
                            ? Colors.green.withAlpha(50)
                            : clr.surfaceContainerHighest),
                  borderRadius: kBorderRadius4,
                ),
                child: Text(
                  e.type.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        (e.type == GrpcEventType.error ||
                            e.type == GrpcEventType.disconnect)
                        ? clr.onErrorContainer
                        : (e.type == GrpcEventType.connect
                              ? Colors.green
                              : null),
                  ),
                ),
              ),
            ),
            DataCell(Text(e.description, style: const TextStyle(fontSize: 12))),
          ],
        );
      }).toList(),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
