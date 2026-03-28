import re

path = 'lib/widgets/mqtt/mqtt_response_pane.dart'
with open(path, 'r') as f:
    text = f.read()

# 1. Update filter filtered events
old_filtered = """    final filtered = _filterTopic.isEmpty
        ? messages
        : messages.where((m) => m.topic.contains(_filterTopic)).toList();"""

new_filtered = """    final filtered = _filterTopic.isEmpty
        ? messages
        : messages.where((m) => m.topic.toLowerCase().contains(_filterTopic.toLowerCase())).toList();

    var filteredEvents = _filterEvent.isEmpty ? events : events.where((e) {
      final query = _filterEvent.toLowerCase();
      final typeMatch = e.type.name.toLowerCase().contains(query);
      final descMatch = e.description.toLowerCase().contains(query);
      final topicMatch = e.topic?.toLowerCase().contains(query) ?? false;
      return typeMatch || descMatch || topicMatch;
    }).toList();"""
text = text.replace(old_filtered, new_filtered)

# 2. Update AnimatedBuilder
old_builder = """        AnimatedBuilder(
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
        ),"""

new_builder = """        AnimatedBuilder(
          animation: _tabCtrl,
          builder: (_, __) {
            if (_tabCtrl.index == 0) {
              return Padding(
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
              );
            } else {
              return Padding(
                padding: kPh8v4,
                child: TextField(
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Filter events…',
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
                  onChanged: (v) => setState(() => _filterEvent = v),
                ),
              );
            }
          },
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
              filteredEvents.isEmpty
                  ? const _EmptyState(
                      icon: Icons.article_outlined,
                      label: 'No events yet',
                    )
                  : _EventList(events: filteredEvents),
            ],
          ),
        ),"""

text = text.replace(old_builder, new_builder)

# 3. Update Event Log list colors
old_event_log = """class _EventList extends StatelessWidget {
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
}"""

new_event_log = """class _EventList extends StatelessWidget {
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
        // Red for errors, Green for positive
        final typeName = e.type.name.toLowerCase();
        final isError = typeName.contains('error') || typeName.contains('connectionfailed');
        final isPositive = typeName.contains('subscribed') || typeName.contains('connected') || typeName.contains('published');
        
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
}"""
text = text.replace(old_event_log, new_event_log)

with open(path, 'w') as f:
    f.write(text)

