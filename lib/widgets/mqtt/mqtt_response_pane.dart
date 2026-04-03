import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/services/mqtt_service.dart';
import 'package:apidash/models/mqtt_request_model.dart';
import 'mqtt_packet_inspector.dart';

final _timeFmt = DateFormat('HH:mm:ss.SSS');

/// Format a numeric value: whole numbers show no decimal, fractions keep digits.
String _fmtNum(double v) {
  if (v.isNaN || v.isInfinite) return '$v';
  final s = v.toStringAsFixed(3);
  if (s.endsWith('.000')) return s.substring(0, s.length - 4);
  var trimmed = s;
  while (trimmed.contains('.') && (trimmed.endsWith('0') || trimmed.endsWith('.'))) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}

// ─── Topic Tree Node ──────────────────────────────────────────────────────────

class _TopicTreeNode {
  final String segment;
  final Map<String, _TopicTreeNode> children = {};
  int _msgCount = 0;

  _TopicTreeNode(this.segment);

  int get totalCount =>
      _msgCount + children.values.fold(0, (s, c) => s + c.totalCount);

  String? get fullTopic => null; // only set on leaf proxy
}

/// Build a tree from a flat list of (topic → count) pairs.
Map<String, _TopicTreeNode> _buildTree(Map<String, int> topicCounts) {
  final roots = <String, _TopicTreeNode>{};
  for (final entry in topicCounts.entries) {
    final parts = entry.key.split('/');
    Map<String, _TopicTreeNode> level = roots;
    for (int i = 0; i < parts.length; i++) {
      final seg = parts[i];
      level.putIfAbsent(seg, () => _TopicTreeNode(seg));
      final node = level[seg]!;
      if (i == parts.length - 1) {
        node._msgCount = entry.value;
      }
      level = node.children;
    }
  }
  return roots;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Try to parse payload as num. Returns null if not numeric.
double? _parseNumeric(String payload) {
  final trimmed = payload.trim();
  return double.tryParse(trimmed);
}

/// Extract numeric fields from a JSON object payload.
/// Returns empty map if payload is not a JSON object.
Map<String, double> _extractJsonNumericFields(String payload) {
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map) {
      final result = <String, double>{};
      for (final entry in decoded.entries) {
        final v = entry.value;
        if (v is num) {
          result[entry.key.toString()] = v.toDouble();
        }
      }
      return result;
    }
  } catch (_) {}
  return {};
}

// ─── Main Widget ──────────────────────────────────────────────────────────────

/// The right‑hand pane shown when API type is MQTT.
class MQTTResponsePane extends ConsumerStatefulWidget {
  const MQTTResponsePane({super.key});

  @override
  ConsumerState<MQTTResponsePane> createState() => _MQTTResponsePaneState();
}

class _MQTTResponsePaneState extends ConsumerState<MQTTResponsePane>
    with SingleTickerProviderStateMixin {
  // ── Tab controller ────────────────────────────────────────────────────────
  late final TabController _tabCtrl;

  // ── Messages tab state ────────────────────────────────────────────────────
  int _filterTypeIndex = 0; // 0:All 1:Sent 2:Received
  String _filterTopic = '';
  late final TextEditingController _topicFilterCtrl;

  // ── Topic tree / history state ────────────────────────────────────────────
  String? _treeFilterTopic; // null = show all; exact topic = filter
  bool _showingHistory = false;

  // ── Events tab state ──────────────────────────────────────────────────────
  int _filterEventIndex = 0;
  String _filterEvent = '';
  late final TextEditingController _eventFilterCtrl;

  // ── Live Graph tab state ──────────────────────────────────────────────────
  // perTopic data: topic → list of (timestamp, value)
  final Map<String, List<_DataPoint>> _graphData = {};
  String? _selectedGraphTopic;
  String? _selectedGraphField; // for JSON payloads

  // ── Replay / export ────────────────────────────────────────────────────────
  String? _replaySuccessTopic; // topic+ts key for 1s checkmark

  @override
  void initState() {
    super.initState();
    _topicFilterCtrl = TextEditingController();
    _eventFilterCtrl = TextEditingController();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _topicFilterCtrl.dispose();
    _eventFilterCtrl.dispose();
    super.dispose();
  }

  // ── Graph data ingestion ──────────────────────────────────────────────────

  void _ingestMessages(List<MQTTMessage> messages) {
    // Rebuild graph data each time from full message list for consistency
    final newData = <String, List<_DataPoint>>{};

    for (final msg in messages) {
      // Try plain number first
      final asNum = _parseNumeric(msg.payload);
      if (asNum != null) {
        newData.putIfAbsent(msg.topic, () => []);
        newData[msg.topic]!.add(
          _DataPoint(
            timestamp: msg.timestamp,
            value: asNum,
            field: null,
            jsonFields: null,
          ),
        );
      } else {
        // Try JSON object
        final fields = _extractJsonNumericFields(msg.payload);
        if (fields.isNotEmpty) {
          newData.putIfAbsent(msg.topic, () => []);
          newData[msg.topic]!.add(
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

    // Trim to last N per topic (enough for zoom + horizontal pan)
    const kGraphPointsCap = 2000;
    for (final topic in newData.keys) {
      if (newData[topic]!.length > kGraphPointsCap) {
        newData[topic] = newData[topic]!.sublist(
          newData[topic]!.length - kGraphPointsCap,
        );
      }
    }

    _graphData
      ..clear()
      ..addAll(newData);

    final newTopics = Set<String>.from(_graphData.keys);
    // Auto-select first topic if none selected yet
    if (_selectedGraphTopic == null && newTopics.isNotEmpty) {
      _selectedGraphTopic = newTopics.first;
    }
    // If selected topic disappeared, reset
    if (_selectedGraphTopic != null &&
        !newTopics.contains(_selectedGraphTopic)) {
      _selectedGraphTopic = newTopics.isNotEmpty ? newTopics.first : null;
      _selectedGraphField = null;
    }

    // Auto-select field if not set or field disappeared
    final points = _selectedGraphTopic != null
        ? _graphData[_selectedGraphTopic] ?? []
        : <_DataPoint>[];
    final availableFields = _availableFields(points);
    if (availableFields.isNotEmpty) {
      if (_selectedGraphField == null ||
          !availableFields.contains(_selectedGraphField)) {
        _selectedGraphField = availableFields.first;
      }
    } else {
      _selectedGraphField = null;
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

  // ── Export ────────────────────────────────────────────────────────────────

  void _exportJson(List<MQTTMessage> messages) {
    final data = messages
        .map(
          (m) => {
            'timestamp': m.timestamp.toIso8601String(),
            'direction': m.isIncoming ? 'in' : 'out',
            'topic': m.topic,
            'payload': m.payload,
          },
        )
        .toList();
    final json = const JsonEncoder.withIndent('  ').convert(data);
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    _showExportDialog('mqtt_session_$ts.json', json, context);
  }

  void _exportCsv(List<MQTTMessage> messages) {
    final buf = StringBuffer('timestamp,direction,topic,payload\n');
    for (final m in messages) {
      final payload = m.payload.replaceAll('"', '""');
      final topic = m.topic.replaceAll('"', '""');
      buf.writeln(
        '"${m.timestamp.toIso8601String()}","${m.isIncoming ? 'in' : 'out'}","$topic","$payload"',
      );
    }
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    _showExportDialog('mqtt_session_$ts.csv', buf.toString(), context);
  }

  void _showExportDialog(String filename, String content, BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (ctx) => AlertDialog(
        title: Text('Export: $filename'),
        content: SizedBox(
          width: 500,
          height: 300,
          child: SelectableText(
            content,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── Replay ────────────────────────────────────────────────────────────────

  Future<void> _replay(MQTTMessage msg) async {
    final service = ref.read(mqttServiceProvider);
    final isConnected =
        ref.read(mqttConnectionStateProvider).value?.isConnected ?? false;
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    await service.publish(
      msg.topic,
      msg.payload,
      qos: msg.qos,
      retain: msg.isRetained,
    );
    final key = '${msg.topic}_${msg.timestamp.millisecondsSinceEpoch}';
    if (mounted) setState(() => _replaySuccessTopic = key);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _replaySuccessTopic = null);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.watch(mqttStateSyncProvider);
    final messages = ref.watch(mqttMessagesProvider);
    final events = ref.watch(mqttEventLogProvider);
    final connState = ref.watch(mqttConnectionStateProvider).value;
    final isConnected = connState?.isConnected ?? false;

    // Ingest graph data whenever messages change
    _ingestMessages(messages);

    final inCount = messages.where((m) => m.isIncoming).length;
    final outCount = messages.where((m) => !m.isIncoming).length;

    // ── Filtered messages ──────────────────────────────────────────────────
    var typeFiltered = messages;
    if (_filterTypeIndex == 1) {
      typeFiltered = messages.where((m) => !m.isIncoming).toList();
    } else if (_filterTypeIndex == 2) {
      typeFiltered = messages.where((m) => m.isIncoming).toList();
    }

    final filtered = _filterTopic.isEmpty
        ? typeFiltered
        : typeFiltered.where((m) => m.topic.contains(_filterTopic)).toList();

    // Tree-filtered view
    List<MQTTMessage> displayMessages;
    if (_treeFilterTopic == null) {
      displayMessages = filtered;
    } else {
      displayMessages = filtered
          .where(
            (m) =>
                m.topic == _treeFilterTopic ||
                m.topic.startsWith('$_treeFilterTopic/'),
          )
          .toList();
    }

    // ── Filtered events ────────────────────────────────────────────────────
    var typeFilteredEvents = events;
    if (_filterEventIndex == 1) {
      typeFilteredEvents = events
          .where((e) => e.type == MQTTEventType.error)
          .toList();
    } else if (_filterEventIndex == 2) {
      typeFilteredEvents = events
          .where((e) => e.type != MQTTEventType.error)
          .toList();
    }
    final filteredEvents = _filterEvent.isEmpty
        ? typeFilteredEvents
        : typeFilteredEvents
              .where(
                (e) => e.description.toLowerCase().contains(
                  _filterEvent.toLowerCase(),
                ),
              )
              .toList();

    // ── Topic tree data ────────────────────────────────────────────────────
    final topicCounts = <String, int>{};
    for (final m in messages) {
      topicCounts[m.topic] = (topicCounts[m.topic] ?? 0) + 1;
    }
    final treeRoots = _buildTree(topicCounts);

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
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Topic Tree'),
                  kHSpacer8,
                  if (topicCounts.isNotEmpty) _Badge(count: topicCounts.length),
                ],
              ),
            ),
          ],
        ),
        // ── Filter bars (per-tab) ───────────────────────────────────────────
        if (_tabCtrl.index == 0) _buildMessagesFilter(messages),
        if (_tabCtrl.index == 1) _buildEventsFilter(),
        // ── Tab content ────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            // Swiping tabs steals horizontal wheel / trackpad pan; use tab bar only.
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // ── Messages ──────────────────────────────────────────────────
              _showingHistory && _treeFilterTopic != null
                  ? _HistoryView(
                      messages: messages
                          .where((m) => m.topic == _treeFilterTopic)
                          .toList(),
                      topic: _treeFilterTopic!,
                      onBack: () => setState(() {
                        _showingHistory = false;
                        _treeFilterTopic = null;
                      }),
                    )
                  : Column(
                      children: [
                        if (_treeFilterTopic != null)
                          _FilterChip(
                            label: _treeFilterTopic!,
                            onClear: () => setState(() {
                              _treeFilterTopic = null;
                              _showingHistory = false;
                            }),
                          ),
                        Expanded(
                          child: displayMessages.isEmpty
                              ? _EmptyState(
                                  icon: Icons.inbox_rounded,
                                  label: isConnected
                                      ? 'Waiting for messages…'
                                      : 'Connect to start receiving',
                                )
                              : _MessageList(
                                  messages: displayMessages,
                                  replaySuccessKey: _replaySuccessTopic,
                                  onReplay: _replay,
                                ),
                        ),
                      ],
                    ),
              // ── Events ────────────────────────────────────────────────────
              events.isEmpty
                  ? const _EmptyState(
                      icon: Icons.article_outlined,
                      label: 'No events yet',
                    )
                  : _EventList(events: filteredEvents),
              // ── Live Graph ────────────────────────────────────────────────
              _LiveGraphTab(
                key: const ValueKey('mqtt_live_graph_tab'),
                graphData: _graphData,
                selectedTopic: _selectedGraphTopic,
                selectedField: _selectedGraphField,
                onTopicChanged: (t) {
                  setState(() {
                    _selectedGraphTopic = t;
                    _selectedGraphField = null;
                    // auto-select field
                    final pts = _graphData[t] ?? [];
                    final fields = _availableFields(pts);
                    if (fields.isNotEmpty) _selectedGraphField = fields.first;
                  });
                },
                onFieldChanged: (f) => setState(() => _selectedGraphField = f),
                getValues: _getValues,
                availableFields: _availableFields,
                notifyParent: () {
                  if (mounted) setState(() {});
                },
              ),
              // ── Topic Tree ─────────────────────────────────────────────────
              _TopicTreeTab(
                roots: treeRoots,
                topicCounts: topicCounts,
                selectedFilter: _treeFilterTopic,
                onTopicSelected: (topic, isLeaf) {
                  setState(() {
                    _treeFilterTopic = topic;
                    _showingHistory = isLeaf;
                  });
                  // Switch to Messages tab
                  _tabCtrl.animateTo(0);
                },
                onShowAll: () => setState(() {
                  _treeFilterTopic = null;
                  _showingHistory = false;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesFilter(List<MQTTMessage> messages) {
    return Padding(
      padding: kPh8v4,
      child: Row(
        children: [
          ADDropdownButton<int>(
            value: _filterTypeIndex,
            onChanged: (v) {
              if (v != null) setState(() => _filterTypeIndex = v);
            },
            values: const [(0, 'All'), (1, 'Sent'), (2, 'Received')],
          ),
          kHSpacer8,
          Expanded(
            child: TextField(
              controller: _topicFilterCtrl,
              onChanged: (v) => setState(() => _filterTopic = v),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Filter by topic...',
                prefixIcon: const Icon(Icons.search, size: 16),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: kBorderRadius8,
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: kBorderRadius8,
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                border: OutlineInputBorder(
                  borderRadius: kBorderRadius8,
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                suffixIcon: _topicFilterCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _topicFilterCtrl.clear();
                          setState(() => _filterTopic = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          kHSpacer8,
          _ExportButton(
            disabled: messages.isEmpty,
            onExportJson: () => _exportJson(messages),
            onExportCsv: () => _exportCsv(messages),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsFilter() {
    return Padding(
      padding: kPh8v4,
      child: Row(
        children: [
          ADDropdownButton<int>(
            value: _filterEventIndex,
            onChanged: (v) {
              if (v != null) setState(() => _filterEventIndex = v);
            },
            values: const [(0, 'All'), (1, 'Error'), (2, 'No Error')],
          ),
          kHSpacer8,
          Expanded(
            child: TextField(
              controller: _eventFilterCtrl,
              onChanged: (v) => setState(() => _filterEvent = v),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Filter events...',
                prefixIcon: const Icon(Icons.search, size: 16),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: kBorderRadius8,
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: kBorderRadius8,
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                border: OutlineInputBorder(
                  borderRadius: kBorderRadius8,
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                suffixIcon: _eventFilterCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _eventFilterCtrl.clear();
                          setState(() => _filterEvent = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data point for graphs ────────────────────────────────────────────────────

class _DataPoint {
  final DateTime timestamp;
  final double value;
  final String? field;
  final Map<String, double>? jsonFields;

  const _DataPoint({
    required this.timestamp,
    required this.value,
    this.field,
    this.jsonFields,
  });
}

// ─── Live Graph Tab ───────────────────────────────────────────────────────────

class _LiveGraphTab extends StatefulWidget {
  final Map<String, List<_DataPoint>> graphData;
  final String? selectedTopic;
  final String? selectedField;
  final void Function(String) onTopicChanged;
  final void Function(String) onFieldChanged;
  final List<double> Function(List<_DataPoint>, String?) getValues;
  final List<String> Function(List<_DataPoint>) availableFields;

  /// Extra rebuild on the MQTT pane (child [setState] should suffice; this
  /// helps graph repaint if the platform misses a frame).
  final VoidCallback? notifyParent;

  const _LiveGraphTab({
    super.key,
    required this.graphData,
    required this.selectedTopic,
    required this.selectedField,
    required this.onTopicChanged,
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
    final oldTopic =
        oldWidget.selectedTopic ??
        (oldWidget.graphData.keys.isNotEmpty
            ? oldWidget.graphData.keys.first
            : null);
    final newTopic =
        widget.selectedTopic ??
        (widget.graphData.keys.isNotEmpty ? widget.graphData.keys.first : null);

    if (oldTopic != newTopic) {
      setState(() {
        _visiblePoints = 50;
        _scrollOffset = 0;
        _autoFollow = true;
        _panPixelRemainder = 0;
      });
    } else if (!_autoFollow) {
      final oldLen = oldWidget.graphData[oldTopic]?.length ?? 0;
      final newLen = widget.graphData[newTopic]?.length ?? 0;
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
      return const _EmptyState(
        icon: Icons.show_chart,
        label: 'No numeric messages yet.\nPublish or receive numeric payloads.',
      );
    }

    final topics = widget.graphData.keys.toList();
    final currentTopic = widget.selectedTopic ?? topics.first;
    final points = widget.graphData[currentTopic] ?? [];
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
              const Text(
                'Topic: ',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              kHSpacer4,
              Expanded(
                child: ADDropdownButton<String>(
                  isExpanded: true,
                  value: currentTopic,
                  onChanged: (v) {
                    if (v != null) widget.onTopicChanged(v);
                  },
                  values: topics.map((t) => (t, t)).toList(),
                ),
              ),
              if (isJsonTopic && fields.isNotEmpty) ...[
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
              ? const _EmptyState(
                  icon: Icons.show_chart,
                  label: 'No data points for this topic yet.',
                )
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
                    bottom: 60, // Pad bottom to prevent overlap with floating button
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
                    bottom: 60 - 16,
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

class _TopicTreeTab extends StatefulWidget {
  final Map<String, _TopicTreeNode> roots;
  final Map<String, int> topicCounts;
  final String? selectedFilter;
  final void Function(String topic, bool isLeaf) onTopicSelected;
  final VoidCallback onShowAll;

  const _TopicTreeTab({
    required this.roots,
    required this.topicCounts,
    required this.selectedFilter,
    required this.onTopicSelected,
    required this.onShowAll,
  });

  @override
  State<_TopicTreeTab> createState() => _TopicTreeTabState();
}

class _TopicTreeTabState extends State<_TopicTreeTab> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    if (widget.roots.isEmpty) {
      return const _EmptyState(
        icon: Icons.account_tree_outlined,
        label: 'No topics yet',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.account_tree_outlined, size: 16),
              kHSpacer8,
              const Text(
                'Topic Tree',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (widget.selectedFilter != null)
                TextButton.icon(
                  onPressed: widget.onShowAll,
                  icon: const Icon(Icons.clear_all, size: 14),
                  label: const Text('Show All', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: widget.roots.entries
                .map(
                  (e) => _TreeNodeWidget(
                    node: e.value,
                    path: e.key,
                    depth: 0,
                    expandedPaths: _expanded,
                    selectedFilter: widget.selectedFilter,
                    allTopicCounts: widget.topicCounts,
                    onExpansionChanged: (path, expanded) {
                      setState(() {
                        if (expanded) {
                          _expanded.add(path);
                        } else {
                          _expanded.remove(path);
                        }
                      });
                    },
                    onSelected: widget.onTopicSelected,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _TreeNodeWidget extends StatelessWidget {
  final _TopicTreeNode node;
  final String path;
  final int depth;
  final Set<String> expandedPaths;
  final String? selectedFilter;
  final Map<String, int> allTopicCounts;
  final void Function(String path, bool expanded) onExpansionChanged;
  final void Function(String topic, bool isLeaf) onSelected;

  const _TreeNodeWidget({
    required this.node,
    required this.path,
    required this.depth,
    required this.expandedPaths,
    required this.selectedFilter,
    required this.allTopicCounts,
    required this.onExpansionChanged,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final isLeaf = node.children.isEmpty;
    final isExpanded = expandedPaths.contains(path);
    final isSelected =
        selectedFilter != null &&
        (selectedFilter == path || selectedFilter!.startsWith('$path/'));
    final count = isLeaf ? (allTopicCounts[path] ?? 0) : node.totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: isSelected
              ? clr.primaryContainer.withAlpha(80)
              : Colors.transparent,
          child: Row(
            children: [
              // ── Expand/collapse area ─ only toggles, never filters ──────
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!isLeaf) onExpansionChanged(path, !isExpanded);
                },
                child: SizedBox(
                  width: 16.0 + depth * 16.0 + 20,
                  height: 36,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0 + depth * 16.0),
                    child: Center(
                      child: !isLeaf
                          ? Icon(
                              isExpanded
                                  ? Icons.expand_more
                                  : Icons.chevron_right,
                              size: 16,
                              color: clr.outline,
                            )
                          : SizedBox(
                              width: 16,
                              child: Icon(
                                Icons.fiber_manual_record,
                                size: 5,
                                color: clr.outline.withAlpha(120),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              // ── Label area ─ tap to select/filter ───────────────────────
              Expanded(
                child: InkWell(
                  onTap: () => onSelected(path, isLeaf),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLeaf ? Icons.topic_outlined : Icons.folder_outlined,
                          size: 14,
                          color: isLeaf ? clr.primary : clr.secondary,
                        ),
                        kHSpacer8,
                        Expanded(
                          child: Text(
                            node.segment,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isLeaf
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: isSelected ? clr.primary : clr.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: clr.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              color: clr.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLeaf && isExpanded)
          ...node.children.entries.map(
            (e) => _TreeNodeWidget(
              node: e.value,
              path: '$path/${e.key}',
              depth: depth + 1,
              expandedPaths: expandedPaths,
              selectedFilter: selectedFilter,
              allTopicCounts: allTopicCounts,
              onExpansionChanged: onExpansionChanged,
              onSelected: onSelected,
            ),
          ),
      ],
    );
  }
}

// ─── History View ─────────────────────────────────────────────────────────────

class _HistoryView extends StatelessWidget {
  final List<MQTTMessage> messages;
  final String topic;
  final VoidCallback onBack;

  const _HistoryView({
    required this.messages,
    required this.topic,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 14),
                label: const Text(
                  'Back to All',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                ),
              ),
              kHSpacer8,
              Expanded(
                child: Text(
                  topic,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: clr.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: messages.isEmpty
              ? const _EmptyState(
                  icon: Icons.history,
                  label: 'No messages for this topic',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  separatorBuilder: (_, _) => kVSpacer4,
                  itemBuilder: (ctx, idx) {
                    final m = messages[messages.length - 1 - idx];
                    return Container(
                      padding: kP8,
                      decoration: BoxDecoration(
                        color: clr.surfaceContainerHighest.withAlpha(80),
                        borderRadius: kBorderRadius8,
                        border: Border.all(
                          color: clr.outlineVariant.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: m.isIncoming
                                  ? clr.secondary.withAlpha(180)
                                  : clr.primary.withAlpha(180),
                              borderRadius: kBorderRadius4,
                            ),
                            child: Text(
                              m.isIncoming ? 'IN' : 'OUT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: clr.onPrimary,
                              ),
                            ),
                          ),
                          kHSpacer8,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _timeFmt.format(m.timestamp),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: clr.outline,
                                  ),
                                ),
                                kVSpacer4,
                                SelectableText(
                                  m.payload.isEmpty
                                      ? '(empty)'
                                      : (double.tryParse(m.payload.trim()) !=
                                                null
                                            ? _fmtNum(
                                                double.parse(m.payload.trim()),
                                              )
                                            : m.payload),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onClear;

  const _FilterChip({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: clr.primaryContainer.withAlpha(120),
        borderRadius: kBorderRadius8,
        border: Border.all(color: clr.primary.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list, size: 12, color: clr.primary),
          kHSpacer4,
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: clr.primary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          kHSpacer4,
          InkWell(
            onTap: onClear,
            child: Icon(Icons.clear, size: 12, color: clr.primary),
          ),
        ],
      ),
    );
  }
}

// ─── Export Button ────────────────────────────────────────────────────────────

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

// ─── Status Bar ───────────────────────────────────────────────────────────────

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
              _durationStr,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
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

// ─── Message List ─────────────────────────────────────────────────────────────

class _MessageList extends ConsumerWidget {
  final List<MQTTMessage> messages;
  final String? replaySuccessKey;
  final Future<void> Function(MQTTMessage) onReplay;

  const _MessageList({
    required this.messages,
    required this.replaySuccessKey,
    required this.onReplay,
  });

  String _protoLabel(MQTTProtocolVersion v) {
    switch (v) {
      case MQTTProtocolVersion.v31:
        return 'MQTT v3.1';
      case MQTTProtocolVersion.v311:
        return 'MQTT v3.1.1';
      case MQTTProtocolVersion.v5:
        return 'MQTT v5.0';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (messages.isEmpty) return const Center(child: Text('No messages yet.'));

    // Read connection metadata for the Connection Context section
    final mqttModel = ref.watch(mqttRequestProvider);
    final brokerHost = mqttModel.brokerUrl.isNotEmpty ? mqttModel.brokerUrl : null;
    final port = mqttModel.port;
    final protocolVersion = _protoLabel(mqttModel.protocolVersion);
    final clientId = mqttModel.clientId.isNotEmpty ? mqttModel.clientId : null;

    final reversed = messages.reversed.toList();
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: reversed.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final m = reversed[idx];
        final key = '${m.topic}_${m.timestamp.millisecondsSinceEpoch}';
        return _MessageTile(
          message: m,
          showReplaySuccess: replaySuccessKey == key,
          onReplay: () => onReplay(m),
          brokerHost: brokerHost,
          port: port,
          protocolVersion: protocolVersion,
          clientId: clientId,
        );
      },
    );
  }
}

class _MessageTile extends StatefulWidget {
  final MQTTMessage message;
  final bool showReplaySuccess;
  final VoidCallback onReplay;
  final String? brokerHost;
  final int? port;
  final String? protocolVersion;
  final String? clientId;

  const _MessageTile({
    required this.message,
    required this.showReplaySuccess,
    required this.onReplay,
    this.brokerHost,
    this.port,
    this.protocolVersion,
    this.clientId,
  });

  @override
  State<_MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<_MessageTile> {
  bool _isRawView = false;

  /// Build the payload widget — JSON gets syntax highlighting, else monospace.
  Widget _buildPayload(BuildContext context, ColorScheme clr) {
    if (_isRawView) {
      return MqttPacketInspector(
        message: widget.message,
        brokerHost: widget.brokerHost,
        port: widget.port,
        protocolVersion: widget.protocolVersion,
        clientId: widget.clientId,
      );
    }
    final payload = widget.message.payload;
    if (payload.isEmpty) {
      return Text(
        '(empty)',
        style: TextStyle(
          color: clr.outline,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    // Try JSON pretty-print + syntax highlighting
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
    // Try numeric format
    final parsed = double.tryParse(payload);
    if (parsed != null) {
      return SelectableText(
        _fmtNum(parsed),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: clr.onSurface,
        ),
      );
    }
    // Plain text / monospace
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: Scrollbar(
        thickness: 4,
        child: SingleChildScrollView(
          child: SelectableText(
            payload,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: clr.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final isIn = widget.message.isIncoming;
    // IN → primary blue accent, OUT → secondary/teal accent
    final accentColor = isIn ? clr.primary : clr.secondary;
    final payloadBytes = utf8.encode(widget.message.payload).length;

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
                            const SizedBox(width: 4),
                            // QoS badge
                            _QosBadge(qos: widget.message.qos, clr: clr),
                            if (widget.message.isRetained) _RetainedBadge(),
                            const SizedBox(width: 6),
                            // Topic name
                            Expanded(
                              child: Text(
                                widget.message.topic,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: clr.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Copy button
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: IconButton(
                                icon: Icon(
                                  Icons.copy_outlined,
                                  size: 13,
                                  color: clr.onSurfaceVariant,
                                ),
                                onPressed: () => Clipboard.setData(
                                  ClipboardData(text: widget.message.payload),
                                ),
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
                                    widget.showReplaySuccess
                                        ? Icons.check_circle_outline
                                        : Icons.replay,
                                    size: 13,
                                    color: widget.showReplaySuccess
                                        ? clr.primary
                                        : clr.onSurfaceVariant,
                                  ),
                                  onPressed: widget.onReplay,
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Re-publish',
                                ),
                              ),
                            const SizedBox(width: 4),
                            
                            // RAW Protocol View Toggle
                            InkWell(
                              onTap: () => setState(() => _isRawView = !_isRawView),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _isRawView ? clr.primary : clr.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _isRawView ? clr.primary : clr.outlineVariant,
                                  ),
                                ),
                                child: Text(
                                  'RAW',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: _isRawView ? FontWeight.bold : FontWeight.normal,
                                    color: _isRawView ? clr.onPrimary : clr.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            // Timestamp
                            Text(
                              _timeFmt.format(widget.message.timestamp),
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
                        _buildPayload(context, clr),
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

// ─── JSON Syntax Highlighting ─────────────────────────────────────────────────

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
    // Token categories → theme color tokens
    final keyColor = clr.primary; // JSON keys
    final stringColor = clr.tertiary; // string values
    final numberColor = clr.secondary; // number values
    final litColor = clr.outline; // true / false / null
    final punctColor = clr.onSurfaceVariant; // {} [] , :

    // Regex: key-or-string | number | literal | punctuation
    final pattern = RegExp(
      r'"[^"\\]*(?:\\.[^"\\]*)*"(?=\s*:)' // JSON key (string followed by :)
      r'|"[^"\\]*(?:\\.[^"\\]*)*"' // string value
      r'|[-]?\d+\.?\d*(?:[eE][+\-]?\d+)?' // number
      r'|true|false|null' // literals
      r'|[{\[\]},:]', // punctuation
      dotAll: true,
    );

    int lastEnd = 0;
    for (final match in pattern.allMatches(json)) {
      if (match.start > lastEnd) {
        // Whitespace / newlines between tokens
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
        // JSON key = string immediately followed by ':'
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

// ─── Event Log ────────────────────────────────────────────────────────────────

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
                  color:
                      (e.type == MQTTEventType.error ||
                          e.type == MQTTEventType.disconnect ||
                          e.type == MQTTEventType.unsubscribe)
                      ? clr.errorContainer
                      : Colors.green.withAlpha(50),
                  borderRadius: kBorderRadius4,
                ),
                child: Text(
                  e.type.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        (e.type == MQTTEventType.error ||
                            e.type == MQTTEventType.disconnect ||
                            e.type == MQTTEventType.unsubscribe)
                        ? clr.onErrorContainer
                        : Colors.green,
                  ),
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

// ─── Shared Helpers ───────────────────────────────────────────────────────────

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
    final clr = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: clr.outlineVariant),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(color: clr.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── QoS & Retained Badges ────────────────────────────────────────────────────

class _QosBadge extends StatelessWidget {
  final int qos;
  final ColorScheme clr;

  const _QosBadge({required this.qos, required this.clr});

  @override
  Widget build(BuildContext context) {
    // QoS 0: default border, QoS 1: primary color border, QoS 2: secondary color border
    final borderColor = qos == 1
        ? clr.primary
        : (qos == 2 ? clr.secondary : clr.outlineVariant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: clr.surfaceContainerHighest,
        border: Border.all(color: borderColor, width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'QoS $qos',
        style: TextStyle(
          fontSize: 9,
          fontWeight: qos > 0 ? FontWeight.bold : FontWeight.normal,
          color: qos > 0 ? borderColor : clr.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _RetainedBadge extends StatelessWidget {
  const _RetainedBadge();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer.withAlpha(140),
          border: Border.all(color: cs.tertiary, width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Retained',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: cs.onTertiaryContainer,
          ),
        ),
      ),
    );
  }
}
