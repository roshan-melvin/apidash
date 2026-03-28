import re

path = 'lib/widgets/grpc_response_pane.dart'
with open(path, 'r') as f:
    text = f.read()

# 1. Add _filterEventString
text = text.replace("String _filterString = '';", "String _filterString = '';\n  String _filterEventString = '';")

# 2. Add filteredEvents logic
old_filtered_events_context = """    final filtered = _filterString.isEmpty
        ? typeFiltered
        : typeFiltered
            .where((m) => m.payload.toString().contains(_filterString))
            .toList();"""
new_filtered_events_context = """    final filtered = _filterString.isEmpty
        ? typeFiltered
        : typeFiltered
            .where((m) => m.payload.toString().toLowerCase().contains(_filterString.toLowerCase()))
            .toList();

    final filteredEvents = _filterEventString.isEmpty
        ? events
        : events
            .where((e) => e.description.toLowerCase().contains(_filterEventString.toLowerCase()) || 
                          e.type.name.toLowerCase().contains(_filterEventString.toLowerCase()))
            .toList();"""
text = text.replace(old_filtered_events_context, new_filtered_events_context)

# 3. Replace AnimatedBuilder
old_builder = """        AnimatedBuilder(
          animation: _tabCtrl,
          builder: (_, __) => _tabCtrl.index == 0
              ? Padding(
                  padding: kPh8v4,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _filterString = v),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 16),
                            hintText: 'Filter payload...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: kBorderRadius8,
                            ),
                          ),
                        ),
                      ),
                      kHSpacer8,
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment<int>(
                            value: 0,
                            label: Text('All', style: TextStyle(fontSize: 12)),
                          ),
                          ButtonSegment<int>(
                            value: 2, // received
                            label: Row(
                              children: [
                                Icon(Icons.arrow_downward, size: 12),
                                SizedBox(width: 4),
                                Text('In', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          ButtonSegment<int>(
                            value: 1, // sent
                            label: Row(
                              children: [
                                Icon(Icons.arrow_upward, size: 12),
                                SizedBox(width: 4),
                                Text('Out', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                        selected: {_filterIndex},
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                        onSelectionChanged: (Set<int> newSelection) {
                          setState(() {
                            _filterIndex = newSelection.first;
                          });
                        },
                      ),
                    ],
                  ),
                )
              : kSizedBoxEmpty,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _MessageStream(messages: filtered),
              _EventLog(events: events),
            ],
          ),
        ),"""

new_builder = """        AnimatedBuilder(
          animation: _tabCtrl,
          builder: (_, __) {
            if (_tabCtrl.index == 0) {
              return Padding(
                padding: kPh8v4,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _filterString = v),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, size: 16),
                          hintText: 'Filter payload...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: kBorderRadius8,
                          ),
                        ),
                      ),
                    ),
                    kHSpacer8,
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment<int>(
                          value: 0,
                          label: Text('All', style: TextStyle(fontSize: 12)),
                        ),
                        ButtonSegment<int>(
                          value: 2,
                          label: Row(
                            children: [
                              Icon(Icons.arrow_downward, size: 12),
                              SizedBox(width: 4),
                              Text('In', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        ButtonSegment<int>(
                          value: 1,
                          label: Row(
                            children: [
                              Icon(Icons.arrow_upward, size: 12),
                              SizedBox(width: 4),
                              Text('Out', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                      selected: {_filterIndex},
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          _filterIndex = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
              );
            } else {
              return Padding(
                padding: kPh8v4,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _filterEventString = v),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, size: 16),
                          hintText: 'Filter events...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: kBorderRadius8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _MessageStream(messages: filtered),
              _EventLog(events: filteredEvents),
            ],
          ),
        ),"""

text = text.replace(old_builder, new_builder)

# 4. Replace Message Bubble
old_message_bubble = """class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final GrpcMessage msg;

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final bg = msg.isIncoming
        ? clr.secondaryContainer.withAlpha(150)
        : clr.primaryContainer.withAlpha(150);
    final borderClr = msg.isIncoming ? clr.secondary : clr.primary;
    final icon = msg.isIncoming ? Icons.arrow_downward : Icons.arrow_upward;
    final label = msg.isIncoming ? 'IN' : 'OUT';

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
                          color: clr.onPrimary),
                    ),
                  ],
                ),
              ),
              kHSpacer8,
              const Spacer(),
              Text(
                _timeFmt.format(msg.timestamp),
                style: TextStyle(fontSize: 10, color: clr.outline),
              ),
            ],
          ),
          kVSpacer8,
          SelectableText(
            msg.payload.toString(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ],
      ),
    );
  }
}"""

new_message_bubble = """class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final GrpcMessage msg;

  @override
  Widget build(BuildContext context) {
    final clrScheme = Theme.of(context).colorScheme;
    final isIncoming = msg.isIncoming;
    
    // Chat bubble alignment
    final alignment = isIncoming ? Alignment.centerLeft : Alignment.centerRight;
    final bubbleColor = isIncoming ? clrScheme.secondaryContainer : clrScheme.primaryContainer;
    final textColor = isIncoming ? clrScheme.onSecondaryContainer : clrScheme.onPrimaryContainer;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: isIncoming ? Radius.zero : const Radius.circular(12),
      bottomRight: isIncoming ? const Radius.circular(12) : Radius.zero,
    );

    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: 0.8,
        child: Container(
          padding: kP8,
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: borderRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isIncoming ? 'IN' : 'OUT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    _timeFmt.format(msg.timestamp),
                    style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7)),
                  ),
                ],
              ),
              kVSpacer4,
              SelectableText(
                msg.payload.toString(),
                style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}"""
text = text.replace(old_message_bubble, new_message_bubble)

# 5. Fix Event Log
old_event = """class _EventLog extends StatelessWidget {
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
            DataCell(Text(_timeFmt.format(e.timestamp),
                style: TextStyle(color: clr.outline, fontSize: 12))),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: clr.surfaceContainerHighest,
                  borderRadius: kBorderRadius4,
                ),
                child: Text(e.type.name.toUpperCase(),
                    style: const TextStyle(fontSize: 10)),
              ),
            ),
            DataCell(
              Text(e.description, style: const TextStyle(fontSize: 12)),
            ),
          ],
        );
      }).toList(),
    );
  }
}"""

new_event = """class _EventLog extends StatelessWidget {
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
        final isError = e.type.name.toLowerCase() == 'error';
        final isPositive = e.type.name.toLowerCase() == 'connect';
        return DataRow(
          cells: [
            DataCell(Text(_timeFmt.format(e.timestamp),
                style: TextStyle(color: clr.outline, fontSize: 12))),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isError
                      ? clr.errorContainer
                      : isPositive
                          ? Colors.green.withOpacity(0.2)
                          : clr.surfaceContainerHighest,
                  borderRadius: kBorderRadius4,
                ),
                child: Text(
                  e.type.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: isError
                        ? clr.onErrorContainer
                        : isPositive
                            ? Colors.green.shade800
                            : clr.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            DataCell(
              Text(e.description, style: const TextStyle(fontSize: 12)),
            ),
          ],
        );
      }).toList(),
    );
  }
}"""
text = text.replace(old_event, new_event)

with open(path, 'w') as f:
    f.write(text)

