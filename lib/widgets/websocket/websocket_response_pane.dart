import 'dart:async';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:math' as math;
import 'package:csv/csv.dart' as csv_pkg;
import 'package:apidash/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/services/websocket_service.dart';

final _timeFmt = DateFormat('HH:mm:ss.SSS');

class WebSocketResponsePane extends ConsumerStatefulWidget {
  const WebSocketResponsePane({super.key});

  @override
  ConsumerState<WebSocketResponsePane> createState() =>
      _WebSocketResponsePaneState();
}

class _WebSocketResponsePaneState extends ConsumerState<WebSocketResponsePane>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _filterString = '';
  String _filterEventString = '';
  int _filterEventIndex = 0;
  final List<_DataPoint> _graphData = [];
  String? _selectedGraphField;
  late final TextEditingController _msgFilterCtrl;
  late final TextEditingController _eventFilterCtrl;

  @override
  void initState() {
    super.initState();
    _msgFilterCtrl = TextEditingController(text: _filterString);
    _eventFilterCtrl = TextEditingController(text: _filterEventString);

    _tabCtrl = TabController(length: 3, vsync: this);
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

  void _ingestMessages(List<WebSocketMessage> messages) {
    final newData = <_DataPoint>[];

    for (final msg in messages) {
      if (msg.payload is! String) continue;
      final String payloadStr = msg.payload.toString();

      final asNum = double.tryParse(payloadStr.trim());
      if (asNum != null) {
        newData.add(
          _DataPoint(
            timestamp: msg.timestamp,
            value: asNum,
            field: null,
            jsonFields: null,
          ),
        );
      } else {
        final fields = _extractJsonNumericFields(payloadStr);
        if (fields.isNotEmpty) {
          newData.add(
            _DataPoint(
              timestamp: msg.timestamp,
              value: fields.values.first,
              field: fields.keys.first,
              jsonFields: fields,
            ),
          );
        }
      }
    }

    const kGraphPointsCap = 2000;
    if (newData.length > kGraphPointsCap) {
      newData.removeRange(0, newData.length - kGraphPointsCap);
    }

    _graphData
      ..clear()
      ..addAll(newData);

    final availableFields = _availableFields(_graphData);
    if (availableFields.isNotEmpty) {
      if (_selectedGraphField == null ||
          !availableFields.contains(_selectedGraphField)) {
        _selectedGraphField = availableFields.first;
      }
    } else {
      _selectedGraphField = null;
    }
  }

  Map<String, double> _extractJsonNumericFields(String payload) {
    final res = <String, double>{};
    if (!payload.trim().startsWith('{')) return res;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _flattenJson(decoded, '', res);
      }
    } catch (_) {}
    return res;
  }

  void _flattenJson(
    Map<String, dynamic> json,
    String prefix,
    Map<String, double> result,
  ) {
    for (final entry in json.entries) {
      final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      final val = entry.value;
      if (val is num) {
        result[key] = val.toDouble();
      } else if (val is Map<String, dynamic>) {
        _flattenJson(val, key, result);
      }
    }
  }

  List<String> _availableFields(List<_DataPoint> points) {
    final fields = <String>{};
    bool hasNoField = false;
    for (final p in points) {
      if (p.field == null && p.jsonFields == null) hasNoField = true;
      if (p.jsonFields != null) fields.addAll(p.jsonFields!.keys);
    }
    if (hasNoField) fields.add('No Field');
    return fields.toList();
  }

  List<double> _getValues(List<_DataPoint> points, String? field) {
    return points.map((p) {
      if (field == 'No Field') {
        return (p.field == null && p.jsonFields == null) ? p.value : double.nan;
      }
      if (field != null && p.jsonFields != null) {
        return p.jsonFields![field] ?? double.nan;
      }
      return p.value;
    }).toList();
  }

  void _exportCsv(List<WebSocketMessage> messages) {
    if (messages.isEmpty) return;
    try {
      final rows = <List<String>>[
        ['Timestamp', 'Direction', 'Size (Bytes)', 'Payload'],
      ];
      for (final m in messages) {
        final dir = m.isIncoming ? 'RECV' : 'SENT';
        final size = utf8.encode(m.payload.toString()).length.toString();
        rows.add([m.timestamp.toString(), dir, size, m.payload.toString()]);
      }
      final csv = csv_pkg.csv.encode(rows);
      saveToDownloads(
        ScaffoldMessenger.of(context),
        content: Uint8List.fromList(utf8.encode(csv)),
        ext: 'csv',
        name: 'websocket_messages',
      );
    } catch (e) {
      debugPrint('CSV Export Error: $e');
    }
  }

  void _exportJson(List<WebSocketMessage> messages) {
    if (messages.isEmpty) return;
    try {
      final data = messages.map((m) {
        return {
          'timestamp': m.timestamp.toIso8601String(),
          'direction': m.isIncoming ? 'RECV' : 'SENT',
          'size': utf8.encode(m.payload.toString()).length,
          'payload': m.payload,
        };
      }).toList();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      saveToDownloads(
        ScaffoldMessenger.of(context),
        content: Uint8List.fromList(utf8.encode(jsonStr)),
        ext: 'json',
        name: 'websocket_messages',
      );
    } catch (e) {
      debugPrint('JSON Export Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedIdStateProvider);
    if (selectedId == null) return kSizedBoxEmpty;

    // Activate the sync listener
    ref.watch(webSocketStateSyncProvider);
    final messages = ref.watch(webSocketMessagesProvider(selectedId));
    final events = ref.watch(webSocketEventLogProvider(selectedId));
    final connState = ref.watch(webSocketStateProvider).value;
    final isConnected = connState?.isConnected ?? false;
    _ingestMessages(messages);

    final inCount = messages.where((m) => m.isIncoming).length;
    final outCount = messages.where((m) => !m.isIncoming).length;

    // Adding filter for Sent/Received/All
    final requestModel = ref.watch(selectedRequestModelProvider);
    final wsModel = requestModel?.websocketRequestModel;
    final filterIndex = wsModel?.filterIndex ?? 0;

    // 0: all, 1: sent, 2: received
    var typeFiltered = messages;
    if (filterIndex == 1) {
      typeFiltered = messages.where((m) => !m.isIncoming).toList();
    } else if (filterIndex == 2) {
      typeFiltered = messages.where((m) => m.isIncoming).toList();
    }

    var typeFilteredEvents = events;
    if (_filterEventIndex == 1) {
      typeFilteredEvents = events
          .where(
            (e) =>
                e.type == WebSocketEventType.error ||
                e.type == WebSocketEventType.disconnect,
          )
          .toList();
    } else if (_filterEventIndex == 2) {
      typeFilteredEvents = events
          .where(
            (e) =>
                e.type != WebSocketEventType.error &&
                e.type != WebSocketEventType.disconnect,
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
          connectedAt: connState?.connectedAt,
        ),
        TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
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
            const Tab(text: 'Live Graph'),
          ],
        ),
        if (_tabCtrl.index == 0)
          Padding(
            padding: kPh8v4,
            child: Row(
              children: [
                ADDropdownButton<int>(
                  value: filterIndex,
                  onChanged: (int? value) {
                    if (value != null) {
                      ref
                          .read(collectionStateNotifierProvider.notifier)
                          .updateWebSocketModel(filterIndex: value);
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
                kHSpacer8,
                _ExportButton(
                  disabled: filtered.isEmpty,
                  onExportCsv: () => _exportCsv(filtered),
                  onExportJson: () => _exportJson(filtered),
                ),
              ],
            ),
          ),
        if (_tabCtrl.index == 1)
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
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _MessageStream(messages: filtered, isConnected: isConnected),
              _EventLog(events: filteredEvents),
              _LiveGraphTab(
                graphData: _graphData,
                selectedField: _selectedGraphField,
                onFieldChanged: (f) => setState(() => _selectedGraphField = f),
                getValues: _getValues,
                availableFields: _availableFields,
                notifyParent: () {
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatefulWidget {
  final bool isConnected;
  final String? error;
  final int inCount;
  final int outCount;
  final DateTime? connectedAt;

  const _StatusBar({
    required this.isConnected,
    this.error,
    required this.inCount,
    required this.outCount,
    this.connectedAt,
  });

  @override
  State<_StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<_StatusBar> {
  Timer? _timer;
  String _durationStr = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _StatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected != oldWidget.isConnected ||
        widget.connectedAt != oldWidget.connectedAt) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.isConnected && widget.connectedAt != null) {
      _updateDuration();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) _updateDuration();
      });
    } else {
      setState(() => _durationStr = '');
    }
  }

  void _updateDuration() {
    if (widget.connectedAt == null) return;
    final diff = DateTime.now().difference(widget.connectedAt!);
    final mm = diff.inMinutes.toString().padLeft(2, '0');
    final ss = (diff.inSeconds % 60).toString().padLeft(2, '0');
    setState(() => _durationStr = '$mm:$ss');
  }

  @override
  Widget build(BuildContext context) {
    final clrScheme = Theme.of(context).colorScheme;

    if (widget.error != null) {
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
                widget.error!,
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
      color: clrScheme.surfaceContainerHighest,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            widget.isConnected ? Icons.circle : Icons.circle_outlined,
            color: widget.isConnected ? Colors.green : Colors.grey,
            size: 10,
          ),
          kHSpacer8,
          Text(
            widget.isConnected ? 'Connected' : 'Disconnected',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          if (_durationStr.isNotEmpty) ...[
            kHSpacer8,
            Text(
              '•',
              style: TextStyle(color: clrScheme.onSurfaceVariant, fontSize: 12),
            ),
            kHSpacer8,
            Text(
              _durationStr,
              style: TextStyle(color: clrScheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
          const Spacer(),
          // Stats
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_downward, size: 14, color: clrScheme.primary),
              kHSpacer4,
              Text(
                'Rx: ${widget.inCount}',
                style: const TextStyle(fontSize: 12),
              ),
              kHSpacer10,
              Icon(Icons.arrow_upward, size: 14, color: clrScheme.secondary),
              kHSpacer4,
              Text(
                'Tx: ${widget.outCount}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageStream extends ConsumerWidget {
  const _MessageStream({required this.messages, required this.isConnected});
  final List<WebSocketMessage> messages;
  final bool isConnected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (messages.isEmpty) return const Center(child: Text('No messages yet.'));

    return ListView.separated(
      padding: kP12,
      // Render newest messages at the bottom
      itemCount: messages.length,
      separatorBuilder: (_, _) => kVSpacer8,
      itemBuilder: (ctx, idx) {
        final m = messages[idx];
        return _MessageBubble(
          msg: m,
          isConnected: isConnected,
          onReplay: () {
            if (isConnected) {
              ref
                  .read(webSocketServiceProvider)
                  .sendMessage(m.payload.toString());
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Not connected'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    required this.msg,
    required this.isConnected,
    this.onReplay,
  });
  final WebSocketMessage msg;
  final bool isConnected;
  final VoidCallback? onReplay;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _showCopySuccess = false;
  bool _showReplaySuccess = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.msg.payload.toString()));
    setState(() => _showCopySuccess = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showCopySuccess = false);
    });
  }

  void _replay() {
    if (!widget.isConnected) {
      if (widget.onReplay != null) widget.onReplay!();
      return;
    }
    if (widget.onReplay != null) widget.onReplay!();
    setState(() => _showReplaySuccess = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showReplaySuccess = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final isIn = widget.msg.isIncoming;
    // Match the same visual style as MQTT IN bubbles
    final accentColor = isIn ? clr.primary : clr.secondary;
    final payloadString = widget.msg.payload.toString();
    final payloadBytes = utf8.encode(payloadString).length;

    return Align(
      alignment: isIn ? Alignment.centerLeft : Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: isIn ? 1.0 : 0.75,
        alignment: isIn ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: clr.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: clr.outlineVariant.withAlpha(60)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left accent border ──────────────────────────────────
                Container(width: 4, color: accentColor),
                // ── Content ─────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Header row ────────────────────────────────────
                        Row(
                          children: [
                            // Direction pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withAlpha(28),
                                border: Border.all(
                                  color: accentColor.withAlpha(90),
                                  width: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isIn
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    size: 10,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    isIn ? 'IN' : 'OUT',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Copy button
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: IconButton(
                                icon: Icon(
                                  _showCopySuccess
                                      ? Icons.check_circle_outline
                                      : Icons.copy_outlined,
                                  size: 13,
                                  color: _showCopySuccess
                                      ? clr.primary
                                      : clr.onSurfaceVariant,
                                ),
                                onPressed: _copy,
                                padding: EdgeInsets.zero,
                                tooltip: 'Copy payload',
                              ),
                            ),
                            // Replay button — OUT only
                            if (!isIn)
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: IconButton(
                                  icon: Icon(
                                    _showReplaySuccess
                                        ? Icons.check_circle_outline
                                        : Icons.replay,
                                    size: 13,
                                    color: _showReplaySuccess
                                        ? clr.primary
                                        : clr.onSurfaceVariant,
                                  ),
                                  onPressed: _replay,
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Re-send',
                                ),
                              ),
                            const SizedBox(width: 4),
                            // Timestamp
                            Text(
                              _timeFmt.format(widget.msg.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: clr.outline,
                              ),
                            ),
                          ],
                        ),
                        // ── Divider ───────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                            height: 1,
                            thickness: 0.5,
                            color: clr.outlineVariant,
                          ),
                        ),
                        // ── Payload ───────────────────────────────────────
                        SelectableText(
                          payloadString,
                          style: TextStyle(
                            color: clr.onSurface,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        // ── Footer: byte size ─────────────────────────────
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '$payloadBytes B',
                              style: TextStyle(
                                fontSize: 10,
                                color: clr.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventLog extends StatelessWidget {
  const _EventLog({required this.events});
  final List<WebSocketEvent> events;

  Color _getBadgeBgColor(WebSocketEventType type, ColorScheme clr) {
    switch (type) {
      case WebSocketEventType.connect:
        return Colors.green.withAlpha(50);
      case WebSocketEventType.disconnect:
      case WebSocketEventType.error:
        return clr.errorContainer;
      case WebSocketEventType.sendText:
      case WebSocketEventType.sendBinary:
        return Colors.orange.withAlpha(50);
      case WebSocketEventType.receiveText:
      case WebSocketEventType.receiveBinary:
        return Colors.blue.withAlpha(50);
      case WebSocketEventType.ping:
      case WebSocketEventType.pong:
        return Colors.teal.withAlpha(50);
    }
  }

  Color _getBadgeTextColor(WebSocketEventType type, ColorScheme clr) {
    switch (type) {
      case WebSocketEventType.connect:
        return Colors.green;
      case WebSocketEventType.disconnect:
      case WebSocketEventType.error:
        return clr.error;
      case WebSocketEventType.sendText:
      case WebSocketEventType.sendBinary:
        return Colors.orange;
      case WebSocketEventType.receiveText:
      case WebSocketEventType.receiveBinary:
        return Colors.blue;
      case WebSocketEventType.ping:
      case WebSocketEventType.pong:
        return Colors.teal;
    }
  }

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
                  color: _getBadgeBgColor(e.type, clr),
                  borderRadius: kBorderRadius4,
                ),
                child: Text(
                  e.type.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getBadgeTextColor(e.type, clr),
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

class _ExportButton extends StatelessWidget {
  final VoidCallback onExportJson;
  final VoidCallback onExportCsv;
  final bool disabled;

  const _ExportButton({
    required this.onExportJson,
    required this.onExportCsv,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final childChip = Chip(
      avatar: Icon(
        Icons.download_outlined,
        size: 14,
        color: disabled ? theme.disabledColor : null,
      ),
      label: Text(
        'Export',
        style: TextStyle(
          fontSize: 12,
          color: disabled ? theme.disabledColor : null,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      backgroundColor: disabled
          ? theme.disabledColor.withValues(alpha: 0.1)
          : null,
      surfaceTintColor: disabled ? Colors.transparent : null,
    );

    if (disabled) {
      return Tooltip(message: 'No messages to export', child: childChip);
    }

    return PopupMenuButton<String>(
      tooltip: 'Export Conversation',
      child: childChip,
      onSelected: (v) {
        if (v == 'json') {
          onExportJson();
        } else if (v == 'csv') {
          onExportCsv();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'json',
          child: Row(
            children: [
              Icon(Icons.data_object, size: 14),
              SizedBox(width: 8),
              Text('Export as JSON', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              Icon(Icons.table_chart_outlined, size: 14),
              SizedBox(width: 8),
              Text('Export as CSV', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DataPoint {
  _DataPoint({
    required this.timestamp,
    required this.value,
    required this.field,
    required this.jsonFields,
  });

  final DateTime timestamp;
  final double value;
  final String? field;
  final Map<String, double>? jsonFields;
}

class _LiveGraphTab extends StatefulWidget {
  final List<_DataPoint> graphData;

  final String? selectedField;

  final void Function(String) onFieldChanged;
  final List<double> Function(List<_DataPoint>, String?) getValues;
  final List<String> Function(List<_DataPoint>) availableFields;

  /// Extra rebuild on the MQTT pane (child [setState] should suffice; this
  /// helps graph repaint if the platform misses a frame).
  final VoidCallback? notifyParent;

  const _LiveGraphTab({
    required this.graphData,

    required this.selectedField,

    required this.onFieldChanged,
    required this.getValues,
    required this.availableFields,
    this.notifyParent,
  });

  @override
  State<_LiveGraphTab> createState() => _LiveGraphTabState();
}

class _LiveGraphTabState extends State<_LiveGraphTab>
    with AutomaticKeepAliveClientMixin {
  static const int _kZoomStep = 5;

  @override
  bool get wantKeepAlive => true;

  /// Desired window size (logical pts). Clamped in [build] by available `n`
  /// and by min window: 10 when `n >= 10`, else 1 so small series can zoom.
  int _visiblePoints = 50;
  int _scrollOffset = 0; // Points back from latest
  bool _autoFollow = true;

  /// Leftover pointer delta when converting pixels → index steps.
  double _panPixelRemainder = 0;

  @override
  void didUpdateWidget(_LiveGraphTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_autoFollow) {
      final oldLen = oldWidget.graphData.length;
      final newLen = widget.graphData.length;
      if (newLen > oldLen) {
        setState(() {
          _scrollOffset += (newLen - oldLen);
        });
      }
    }
  }

  /// Fewer points on screen (magnify).
  void _zoomIn(int n) {
    if (n < 1) return;
    if (n < 10) {
      final cur = _visiblePoints.clamp(1, n);
      final next = (cur - 1).clamp(1, n);
      if (next == cur) return;
      setState(() {
        _visiblePoints = next;
        _scrollOffset = 0;
        _autoFollow = true;
        _panPixelRemainder = 0;
      });
    } else {
      final next = (_visiblePoints - _kZoomStep).clamp(10, 100);
      if (next == _visiblePoints) return;
      setState(() {
        _visiblePoints = next;
        _scrollOffset = 0;
        _autoFollow = true;
        _panPixelRemainder = 0;
      });
    }
    widget.notifyParent?.call();
  }

  /// More points on screen (see more history).
  void _zoomOut(int n) {
    if (n < 1) return;
    if (n < 10) {
      final cur = _visiblePoints.clamp(1, n);
      final next = (cur + 1).clamp(1, n);
      if (next == cur) return;
      setState(() {
        _visiblePoints = next;
        _scrollOffset = 0;
        _autoFollow = true;
        _panPixelRemainder = 0;
      });
    } else {
      final next = (_visiblePoints + _kZoomStep).clamp(10, 100);
      if (next == _visiblePoints) return;
      setState(() {
        _visiblePoints = next;
        _scrollOffset = 0;
        _autoFollow = true;
        _panPixelRemainder = 0;
      });
    }
    widget.notifyParent?.call();
  }

  void _pinchZoomDelta(int delta, int n) {
    if (n < 1) return;
    if (n < 10) {
      if (delta < 0) {
        _zoomIn(n);
      } else if (delta > 0) {
        _zoomOut(n);
      }
      return;
    }
    final next = (_visiblePoints + delta).clamp(10, 100);
    if (next == _visiblePoints) return;
    setState(() {
      _visiblePoints = next;
      _scrollOffset = 0;
      _autoFollow = true;
      _panPixelRemainder = 0;
    });
    widget.notifyParent?.call();
  }

  /// Pan the visible window in index space (~[kPxPerPoint] logical px per step).
  void _onChartPanPixels(double pixelDelta, int maxPan) {
    if (maxPan <= 0 || pixelDelta == 0) return;
    const kPxPerPoint = 8.0;
    setState(() {
      _panPixelRemainder += pixelDelta;
      final deltaIdx = (_panPixelRemainder / kPxPerPoint).truncate();
      if (deltaIdx != 0) {
        _panPixelRemainder -= deltaIdx * kPxPerPoint;
        _scrollOffset = (_scrollOffset + deltaIdx).clamp(0, maxPan);
        _autoFollow = _scrollOffset == 0;
      }
    });
  }

  void _jumpToLatest() {
    setState(() {
      _scrollOffset = 0;
      _autoFollow = true;
      _panPixelRemainder = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final clr = Theme.of(context).colorScheme;

    if (widget.graphData.isEmpty) {
      return const Center(
        child: Text(
          'No numeric messages yet.\nPublish or receive numeric payloads.',
        ),
      );
    }

    final points = widget.graphData;
    final fields = widget.availableFields(points);
    final isJsonTopic = fields.isNotEmpty;
    final currentField = isJsonTopic ? widget.selectedField : null;
    final allValues = widget.getValues(points, currentField);

    // If autoFollow is off and points increased, scrollOffset increases to keep view locked
    // This is handled by slicing from the end

    final n = allValues.length;
    final int visibleCount;
    if (n < 1) {
      visibleCount = 0;
    } else if (n < 10) {
      visibleCount = _visiblePoints.clamp(1, n);
    } else {
      final cap = n > 100 ? 100 : n;
      visibleCount = _visiblePoints.clamp(10, cap);
    }
    final maxPan = math.max(0, n - visibleCount);

    if (_scrollOffset > maxPan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _scrollOffset = maxPan);
      });
    }

    final effOffset = _scrollOffset.clamp(0, maxPan);
    final displayedPointCount = visibleCount;

    int endIdx = n - effOffset;
    if (endIdx < visibleCount) endIdx = visibleCount;
    final startIdx = (endIdx - visibleCount).clamp(0, n);
    final endSlice = endIdx.clamp(startIdx, n);

    final visibleValues = allValues.sublist(startIdx, endSlice);
    final validValues = visibleValues
        .where((v) => !v.isNaN && v.isFinite)
        .toList();

    double dataMin;
    double dataMax;
    if (validValues.isEmpty) {
      dataMin = 0;
      dataMax = 1;
    } else {
      dataMin = validValues.reduce(math.min);
      dataMax = validValues.reduce(math.max);
    }

    double paddedMin;
    double paddedMax;
    if (dataMin == dataMax) {
      paddedMin = dataMin - 1;
      paddedMax = dataMax + 1;
    } else {
      final span = dataMax - dataMin;
      paddedMin = dataMin - span * 0.1;
      paddedMax = dataMax + span * 0.1;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              if (fields.isNotEmpty) ...[
                kHSpacer8,
                const Text(
                  'Field: ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                kHSpacer4,
                Expanded(
                  child: ADDropdownButton<String>(
                    isExpanded: true,
                    value: currentField ?? fields.first,
                    onChanged: (v) {
                      if (v != null) widget.onFieldChanged(v);
                    },
                    values: fields
                        .map(
                          (f) => (
                            f,
                            double.tryParse(f) != null
                                ? _fmtNum(double.parse(f))
                                : f,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (points.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Range: ${_fmtNum(paddedMin)} … ${_fmtNum(paddedMax)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: clr.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _GraphZoomBar(
                  visibleCount: displayedPointCount,
                  totalPoints: n,
                  iconColor:
                      IconTheme.of(context).color ?? clr.onSurfaceVariant,
                  onZoomIn: () => _zoomIn(n),
                  onZoomOut: () => _zoomOut(n),
                ),
              ],
            ),
          ),
        Expanded(
          child: points.isEmpty
              ? const Center(child: Text('No data points for this topic yet.'))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
                  child: _SparklineChart(
                    values: visibleValues,
                    paddedMin: paddedMin,
                    paddedMax: paddedMax,
                    color: clr.primary,
                    maxPan: maxPan,
                    visibleCount: visibleCount,
                    endIdx: endIdx,
                    isAtLatest: _autoFollow && effOffset == 0,
                    onPinchZoom: (d) => _pinchZoomDelta(d, n),
                    onChartPanPixels: (px) => _onChartPanPixels(px, maxPan),
                    onJumpToLatest: _jumpToLatest,
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Graph zoom toolbar (outside chart hit targets) ───────────────────────────

class _GraphZoomBar extends StatelessWidget {
  final int visibleCount;
  final int totalPoints;
  final Color iconColor;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _GraphZoomBar({
    required this.visibleCount,
    required this.totalPoints,
    required this.iconColor,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    // ElevatedButton avoids IconButton hit-test quirks on some Linux builds.
    final btnStyle = ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: clr.surfaceContainerHigh,
      foregroundColor: iconColor,
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      maximumSize: const Size(44, 44),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    return Material(
      color: clr.surfaceContainerHighest.withAlpha(220),
      borderRadius: BorderRadius.circular(8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Show more points (zoom out)',
              child: ElevatedButton(
                onPressed: onZoomOut,
                style: btnStyle,
                child: Icon(Icons.remove, size: 22, color: iconColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '$visibleCount / $totalPoints',
                style: TextStyle(
                  fontSize: 11,
                  color: clr.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Tooltip(
              message: 'Show fewer points (zoom in)',
              child: ElevatedButton(
                onPressed: onZoomIn,
                style: btnStyle,
                child: Icon(Icons.add, size: 22, color: iconColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sparkline Chart ──────────────────────────────────────────────────────────

class _SparklineChart extends StatefulWidget {
  final List<double> values;
  final double paddedMin;
  final double paddedMax;
  final Color color;
  final int maxPan;
  final int visibleCount;
  final int endIdx;
  final bool isAtLatest;
  final void Function(int delta) onPinchZoom;
  final void Function(double pixelDelta) onChartPanPixels;
  final VoidCallback onJumpToLatest;

  const _SparklineChart({
    required this.values,
    required this.paddedMin,
    required this.paddedMax,
    required this.color,
    required this.maxPan,
    required this.visibleCount,
    required this.endIdx,
    required this.isAtLatest,
    required this.onPinchZoom,
    required this.onChartPanPixels,
    required this.onJumpToLatest,
  });

  @override
  State<_SparklineChart> createState() => _SparklineChartState();
}

class _SparklineChartState extends State<_SparklineChart> {
  double? _scaleGestureBaseline;
  double? _panZoomScaleBaseline;

  void _handlePointerScroll(PointerScrollEvent event) {
    var dx = event.scrollDelta.dx;
    var dy = event.scrollDelta.dy;
    if (HardwareKeyboard.instance.isShiftPressed && dx == 0 && dy != 0) {
      dx = dy;
      dy = 0;
    } else if (widget.maxPan > 0) {
      // Zoomed in: use whichever axis is larger; vertical wheel pans horizontally.
      if (dx.abs() < dy.abs()) {
        dx = dy;
        dy = 0;
      }
    } else {
      if (dx == 0) return;
      if (dx.abs() < dy.abs()) return;
    }
    if (dx == 0) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      // Pointer deltas are small — scale up slightly for wheel ticks.
      widget.onChartPanPixels(dx * 2.5);
    });
  }

  void _handleScaleStart(ScaleStartDetails _) {
    _scaleGestureBaseline = null;
  }

  void _handleScaleUpdate(ScaleUpdateDetails d) {
    if (_scaleGestureBaseline == null) {
      _scaleGestureBaseline = d.scale;
      return;
    }
    final ratio = d.scale / _scaleGestureBaseline!;
    if (ratio >= 1.05) {
      widget.onPinchZoom(5);
      _scaleGestureBaseline = d.scale;
    } else if (ratio <= 0.95) {
      widget.onPinchZoom(-5);
      _scaleGestureBaseline = d.scale;
    }
  }

  void _handleScaleEnd(ScaleEndDetails _) {
    _scaleGestureBaseline = null;
  }

  void _handlePanZoomStart(PointerPanZoomStartEvent _) {
    _panZoomScaleBaseline = null;
  }

  void _handlePanZoomUpdate(PointerPanZoomUpdateEvent e) {
    if (e.panDelta.dx != 0 && e.panDelta.dx.abs() >= e.panDelta.dy.abs()) {
      widget.onChartPanPixels(e.panDelta.dx);
    } else if (widget.maxPan > 0 &&
        e.panDelta.dy != 0 &&
        e.panDelta.dy.abs() > e.panDelta.dx.abs()) {
      widget.onChartPanPixels(e.panDelta.dy);
    }
    if (_panZoomScaleBaseline == null) {
      _panZoomScaleBaseline = e.scale;
      return;
    }
    final ratio = e.scale / _panZoomScaleBaseline!;
    if (ratio >= 1.05) {
      widget.onPinchZoom(5);
      _panZoomScaleBaseline = e.scale;
    } else if (ratio <= 0.95) {
      widget.onPinchZoom(-5);
      _panZoomScaleBaseline = e.scale;
    }
  }

  void _handlePanZoomEnd(PointerPanZoomEndEvent _) {
    _panZoomScaleBaseline = null;
  }

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Chart + wheel/pinch. Pan uses Listener (not GestureDetector) so +/−
                  // InkWells are not defeated by the pan gesture arena.
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 60,
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerMove: (PointerMoveEvent e) {
                        if (widget.maxPan <= 0) return;
                        if (!e.down) return;
                        final dx = e.delta.dx;
                        final dy = e.delta.dy;
                        if (dx == 0 && dy == 0) return;
                        if (dx.abs() >= dy.abs()) {
                          widget.onChartPanPixels(dx);
                        } else {
                          widget.onChartPanPixels(dy);
                        }
                      },
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerSignal: (event) {
                          if (event is PointerScrollEvent) {
                            _handlePointerScroll(event);
                          }
                        },
                        onPointerPanZoomStart: _handlePanZoomStart,
                        onPointerPanZoomUpdate: _handlePanZoomUpdate,
                        onPointerPanZoomEnd: _handlePanZoomEnd,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onScaleStart: _handleScaleStart,
                          onScaleUpdate: _handleScaleUpdate,
                          onScaleEnd: _handleScaleEnd,
                          child: CustomPaint(
                            size: Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                            painter: _SparklinePainter(
                              values: widget.values,
                              paddedMin: widget.paddedMin,
                              paddedMax: widget.paddedMax,
                              color: widget.color,
                              gridColor: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                              dotColor: widget.color,
                              textColor: clr.onSurfaceVariant,
                              visibleCount: widget.visibleCount,
                              endIdx: widget.endIdx,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 44,
                    left: 8,
                    child: Text(
                      'Min: ${_fmtNum(widget.paddedMin)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: clr.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!widget.isAtLatest)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: clr.surfaceContainerHighest.withAlpha(200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '← older',
                          style: TextStyle(fontSize: 10, color: clr.outline),
                        ),
                      ),
                    ),
                  if (!widget.isAtLatest)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: FilledButton.icon(
                        onPressed: widget.onJumpToLatest,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: clr.secondaryContainer,
                          foregroundColor: clr.onSecondaryContainer,
                        ),
                        icon: const Icon(Icons.arrow_downward, size: 12),
                        label: const Text(
                          '↓ Jump to latest',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final double paddedMin;
  final double paddedMax;
  final Color color;
  final Color gridColor;
  final Color dotColor;
  final Color textColor;
  final int visibleCount;
  final int endIdx;
  static const double _dotR = 4.0;

  _SparklinePainter({
    required this.values,
    required this.paddedMin,
    required this.paddedMax,
    required this.color,
    required this.gridColor,
    required this.dotColor,
    required this.textColor,
    required this.visibleCount,
    required this.endIdx,
  });

  double _yPixel(double v, double h) {
    if (!v.isFinite) return (h / 2).clamp(_dotR, h - _dotR);
    final span = paddedMax - paddedMin;
    if (span <= 0) return (h / 2).clamp(_dotR, h - _dotR);

    final y = h - ((v - paddedMin) / span) * h;
    return y.clamp(_dotR, h - _dotR); // Apply the Y clamp to every single point
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final h = size.height;
    final w = size.width;
    final span = paddedMax - paddedMin;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 11,
    );

    // 4 evenly spaced grid lines: 1/5, 2/5, 3/5, 4/5 of height
    for (int i = 1; i <= 4; i++) {
      final y = h * i / 5;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);

      final val = paddedMax - (span * i / 5);
      final textSpan = TextSpan(
        text: _fmtNum(val),
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height - 2));
    }

    if (span > 0 && paddedMin < 0 && paddedMax > 0) {
      final zeroY = _yPixel(0, h);
      final zeroPaint = Paint()
        ..color = gridColor.withAlpha(200)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(0, zeroY), Offset(w, zeroY), zeroPaint);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withAlpha(30)
      ..style = PaintingStyle.fill;

    final nv = values.length;

    double xPos(int i) {
      if (visibleCount <= 1) return w - _dotR;

      final wStart = endIdx - visibleCount;
      final originalIdx = endIdx - nv + i;
      return ((originalIdx - wStart) / (visibleCount - 1)) * w;
    }

    // Collect valid points
    List<Offset> validPoints = [];
    for (int i = 0; i < nv; i++) {
      if (values[i].isFinite) {
        // Clamp all calculated X positions so the line NEVER extends past chartWidth - dotRadius
        double x = xPos(i).clamp(0.0, w - _dotR);
        double y = _yPixel(values[i], h);
        validPoints.add(Offset(x, y));
      }
    }

    if (validPoints.length >= 2) {
      final path = Path();
      final fillPath = Path();

      path.moveTo(validPoints.first.dx, validPoints.first.dy);
      fillPath.moveTo(validPoints.first.dx, h);
      fillPath.lineTo(validPoints.first.dx, validPoints.first.dy);

      for (int i = 1; i < validPoints.length; i++) {
        path.lineTo(validPoints[i].dx, validPoints[i].dy);
        fillPath.lineTo(validPoints[i].dx, validPoints[i].dy);
      }

      fillPath.lineTo(validPoints.last.dx, h);
      fillPath.lineTo(validPoints.first.dx, h);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, linePaint);
    }

    if (validPoints.isNotEmpty) {
      // The dot representing the latest value is placed exactly at the end of the line
      Offset lastP = validPoints.last;

      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastP, _dotR, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values ||
      old.paddedMin != paddedMin ||
      old.paddedMax != paddedMax ||
      old.color != color ||
      old.visibleCount != visibleCount ||
      old.endIdx != endIdx;
}

// ─── Topic Tree Tab ───────────────────────────────────────────────────────────

String _fmtNum(double v) {
  if (v.isNaN) return 'NaN';
  if (v.isInfinite) return 'Inf';
  final s = v.toStringAsFixed(2);
  if (s.endsWith('.00')) return s.substring(0, s.length - 3);
  if (s[s.length - 1] == '0') return s.substring(0, s.length - 1);
  return s;
}
