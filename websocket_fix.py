import re

path = 'lib/widgets/websocket/websocket_response_pane.dart'
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

# 3. Replace AnimatedBuilder builder method body for BOTH filters
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
                            value: 2, // Map to received
                            label: Row(
                              children: [
                                Icon(Icons.arrow_downward, size: 12),
                                SizedBox(width: 4),
                                Text('In', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          ButtonSegment<int>(
                            value: 1, // Map to sent
                            label: Row(
                              children: [
                                Icon(Icons.arrow_upward, size: 12),
                                SizedBox(width: 4),
                                Text('Out', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                        selected: {filterIndex},
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                        onSelectionChanged: (Set<int> newSelection) {
                          ref.read(collectionStateNotifierProvider.notifier).updateWebSocketModel(
                                filterIndex: newSelection.first,
                              );
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
                      selected: {filterIndex},
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      onSelectionChanged: (Set<int> newSelection) {
                        ref.read(collectionStateNotifierProvider.notifier).updateWebSocketModel(
                              filterIndex: newSelection.first,
                            );
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

with open(path, 'w') as f:
    f.write(text)

