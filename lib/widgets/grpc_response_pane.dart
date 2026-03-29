import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:apidash/utils/save_utils.dart';
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

  void _exportCsv(List<GrpcMessage> messages) {
    if (messages.isEmpty) return;
    try {
      final header = 'Date,Time,Direction,Size (Bytes),Payload\n';
      final rows = messages
          .map((m) {
            final d = DateFormat('yyyy-MM-dd').format(m.timestamp);
            final t = _timeFmt.format(m.timestamp);
            final dir = m.isIncoming ? 'RECV' : 'SENT';
            final size = utf8.encode(m.payload.toString()).length;
            final p = m.payload.toString().replaceAll('"', '""');
            return '$d,$t,$dir,$size,"$p"';
          })
          .join('\n');
      final csv = header + rows;
      saveToDownloads(
        ScaffoldMessenger.of(context),
        content: Uint8List.fromList(utf8.encode(csv)),
        ext: 'csv',
        name: 'grpc_messages',
      );
    } catch (e) {
      debugPrint('CSV Export Error: $e');
    }
  }

  void _exportJson(List<GrpcMessage> messages) {
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
        name: 'grpc_messages',
      );
    } catch (e) {
      debugPrint('JSON Export Error: $e');
    }
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
              .where(
                (m) => m.payload.toString().toLowerCase().contains(
                  _filterString.toLowerCase(),
                ),
              )
              .toList();

    DateTime? connectedAt;
    if (isConnected) {
      try {
        connectedAt = events
            .lastWhere((e) => e.type == GrpcEventType.connect)
            .timestamp;
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusBar(
          isConnected: isConnected,
          connectedAt: connectedAt,
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
                  kHSpacer8,
                  _ExportButton(
                    disabled: filtered.isEmpty,
                    onExportCsv: () => _exportCsv(filtered),
                    onExportJson: () => _exportJson(filtered),
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
              _MessageStream(
                messages: filtered,
                selectedId: selectedId,
                isConnected: isConnected,
              ),
              _EventLog(events: filteredEvents),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatefulWidget {
  const _StatusBar({
    required this.isConnected,
    this.connectedAt,
    this.error,
    required this.inCount,
    required this.outCount,
  });

  final bool isConnected;
  final DateTime? connectedAt;
  final String? error;
  final int inCount;
  final int outCount;

  @override
  State<_StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<_StatusBar> {
  Timer? _timer;
  String _durationStr = '';
  String? _hiddenError;
  bool _showErrorDetails = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _StatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error != oldWidget.error) {
      _hiddenError = null;
      _showErrorDetails = false;
    }
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

    if (widget.error != null && widget.error != _hiddenError) {
      final isLongError =
          widget.error!.length > 100 || widget.error!.contains('\n');
      return Container(
        color: clrScheme.errorContainer,
        width: double.infinity,
        padding: kP8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: clrScheme.error, size: 18),
                kHSpacer8,
                Expanded(
                  child: Text(
                    isLongError && !_showErrorDetails
                        ? '${widget.error!.replaceAll('\n', ' ').substring(0, 100)}...'
                        : widget.error!.replaceAll('\n', ' '),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: clrScheme.onErrorContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLongError)
                  TextButton(
                    onPressed: () =>
                        setState(() => _showErrorDetails = !_showErrorDetails),
                    child: Text(
                      _showErrorDetails ? 'Hide details' : 'Show details',
                      style: TextStyle(color: clrScheme.onErrorContainer),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: clrScheme.onErrorContainer,
                  ),
                  onPressed: () => setState(() => _hiddenError = widget.error),
                ),
              ],
            ),
            if (_showErrorDetails)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 26.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        widget.error!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: clrScheme.onErrorContainer,
                        ),
                      ),
                    ),
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
                  color: widget.isConnected ? Colors.green : Colors.grey,
                ),
              ),
              kHSpacer8,
              Text(
                widget.isConnected ? 'Connected' : 'Disconnected',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (widget.isConnected && _durationStr.isNotEmpty) ...[
                kHSpacer8,
                Icon(Icons.timer_outlined, size: 14, color: clrScheme.outline),
                const SizedBox(width: 4),
                Text(
                  _durationStr,
                  style: TextStyle(fontSize: 12, color: clrScheme.outline),
                ),
              ],
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
                  Text('Rx: ${widget.inCount}'),
                  const SizedBox(width: 16),
                  Icon(Icons.arrow_upward, size: 14, color: clrScheme.primary),
                  kHSpacer4,
                  Text('Tx: ${widget.outCount}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageStream extends ConsumerWidget {
  const _MessageStream({
    required this.messages,
    required this.selectedId,
    required this.isConnected,
  });
  final List<GrpcMessage> messages;
  final String selectedId;
  final bool isConnected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (messages.isEmpty) return const Center(child: Text('No messages yet.'));

    return ListView.separated(
      padding: kP12,
      itemCount: messages.length,
      separatorBuilder: (_, _) => kVSpacer8,
      itemBuilder: (ctx, idx) {
        final m = messages[idx];
        return _MessageBubble(
          msg: m,
          isConnected: isConnected,
          onReplay: m.isIncoming
              ? null
              : () {
                  final requestModel = ref
                      .read(collectionStateNotifierProvider)?[selectedId]
                      ?.grpcRequestModel;
                  if (requestModel != null) {
                    ref
                        .read(grpcServiceProvider)
                        .send(message: m.payload, requestModel: requestModel);
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
  final GrpcMessage msg;
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

  Widget _buildPayload(BuildContext context, ColorScheme clr) {
    final payload = widget.msg.payload;
    if (payload.isEmpty) {
      return Text(
        '(empty)',
        style: TextStyle(
          color: clr.outline,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map || decoded is List) {
        final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: Scrollbar(
            thickness: 4,
            child: SingleChildScrollView(
              child: _JsonHighlightText(json: pretty, clr: clr),
            ),
          ),
        );
      }
    } catch (_) {}

    final parsed = double.tryParse(payload);
    if (parsed != null) {
      return SelectableText.rich(
        TextSpan(
          text: _fmtNum(parsed),
          style: TextStyle(
            color: clr.secondary,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      );
    }

    return SelectableText(
      payload,
      style: TextStyle(
        color: clr.onSurface,
        fontFamily: 'monospace',
        fontSize: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final isIn = widget.msg.isIncoming;
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
                // left accent border
                Container(width: 4, color: accentColor),
                // Content
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
                        // Header row
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
                        // Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                            height: 1,
                            thickness: 0.5,
                            color: clr.outlineVariant,
                          ),
                        ),
                        // Payload
                        _buildPayload(context, clr),
                        // Footer: byte size
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
                      : Colors.green.withAlpha(50),
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
                        : Colors.green,
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

class _JsonHighlightText extends StatelessWidget {
  final String json;
  final ColorScheme clr;

  const _JsonHighlightText({required this.json, required this.clr});

  @override
  Widget build(BuildContext context) {
    final spans = _tokenize();
    return SelectableText.rich(
      TextSpan(children: spans),
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
    );
  }

  List<TextSpan> _tokenize() {
    final spans = <TextSpan>[];
    final keyColor = clr.primary;
    final stringColor = clr.tertiary;
    final numberColor = clr.secondary;
    final litColor = clr.outline;
    final punctColor = clr.onSurfaceVariant;

    final pattern = RegExp(
      r'"[^"\\]*(?:\\.[^"\\]*)*"(?=\s*:)'
      r'|"[^"\\]*(?:\\.[^"\\]*)*"'
      r'|[-]?\d+\.?\d*(?:[eE][+\-]?\d+)?'
      r'|true|false|null'
      r'|[{\[\]},:]',
      dotAll: true,
    );

    int lastEnd = 0;
    for (final match in pattern.allMatches(json)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: json.substring(lastEnd, match.start),
            style: TextStyle(color: clr.onSurface),
          ),
        );
      }
      final tok = match.group(0)!;
      Color color;
      if (tok.startsWith('"')) {
        final afterTok = json.substring(match.end).trimLeft();
        if (afterTok.startsWith(':')) {
          color = keyColor;
        } else {
          color = stringColor;
        }
      } else if (tok == 'true' || tok == 'false' || tok == 'null') {
        color = litColor;
      } else if (RegExp(r'^-?\d').hasMatch(tok)) {
        color = numberColor;
      } else {
        color = punctColor;
      }
      final displayTok =
          (color == numberColor &&
              RegExp(r'^-?\d').hasMatch(tok) &&
              double.tryParse(tok) != null)
          ? _fmtNum(double.parse(tok))
          : tok;
      spans.add(
        TextSpan(
          text: displayTok,
          style: TextStyle(color: color),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < json.length) {
      spans.add(
        TextSpan(
          text: json.substring(lastEnd),
          style: TextStyle(color: clr.onSurface),
        ),
      );
    }
    return spans;
  }
}

String _fmtNum(double v) {
  if (v.isNaN || v.isInfinite) return '$v';
  final s = v.toStringAsFixed(3);
  if (s.endsWith('.000')) return s.substring(0, s.length - 4);
  var trimmed = s;
  while (trimmed.contains('.') &&
      (trimmed.endsWith('0') || trimmed.endsWith('.'))) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
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
