import re

def rewrite():
    path = "lib/widgets/websocket/websocket_response_pane.dart"
    with open(path, "r") as f:
        content = f.read()

    # Add State variable:
    if "String _filterEventString = '';" not in content:
        content = content.replace("String _filterString = '';", "String _filterString = '';\n  String _filterEventString = '';")

    # Fix filtering logic
    old_filtered = '''    final inCount = messages.where((m) => m.isIncoming).length;
    final outCount = messages.where((m) => !m.isIncoming).length;

    final filtered = _filterString.isEmpty
        ? messages
        : messages
            .where((m) => m.data.toLowerCase().contains(_filterString.toLowerCase()))
            .toList();'''

    new_filtered = '''    final inCount = messages.where((m) => m.isIncoming).length;
    final outCount = messages.where((m) => !m.isIncoming).length;

    final filtered = _filterString.isEmpty
        ? messages
        : messages
            .where((m) => m.data.toLowerCase().contains(_filterString.toLowerCase()))
            .toList();

    final filteredEvents = _filterEventString.isEmpty
        ? events
        : events
            .where((e) => e.description.toLowerCase().contains(_filterEventString.toLowerCase()))
            .toList();
'''
    if "filteredEvents" not in content:
        content = content.replace(old_filtered.strip(), new_filtered.strip())

    # Replace Builder
    pattern = re.compile(r'AnimatedBuilder\(\s*animation: _tabCtrl,\s*builder: \(_, __\) => _tabCtrl\.index == 0\s*\? Padding\(.*?: kSizedBoxEmpty,\s*\),', re.DOTALL)
    
    new_builder = '''AnimatedBuilder(
          animation: _tabCtrl,
          builder: (_, __) {
            final isChat = _tabCtrl.index == 0;
            return Padding(
              padding: kPh8v4,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: ValueKey('ws_filter_${_tabCtrl.index}'),
                      initialValue: isChat ? _filterString : _filterEventString,
                      onChanged: (v) {
                        if (isChat) {
                          setState(() => _filterString = v);
                        } else {
                          setState(() => _filterEventString = v);
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                        prefixIcon: const Icon(Icons.filter_list_rounded, size: 16),
                        hintText: isChat ? 'Filter payload...' : 'Filter events...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                        ),
                      ),
                    ),
                  ),
                  kHSpacer8,
                  if (isChat)
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
                        ref
                            .read(collectionStateNotifierProvider.notifier)
                            .updateWebSocketModel(
                              filterIndex: newSelection.first,
                            );
                      },
                    ),
                  if (isChat) kHSpacer8,
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(collectionStateNotifierProvider.notifier).clearWebSocketMessages(selectedId);
                      ref.read(collectionStateNotifierProvider.notifier).clearWebSocketEvents(selectedId);
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            );
          },
        ),'''
        
    content = pattern.sub(new_builder, content)
    
    # Add error checking for `filteredEvents` vs `events`
    content = content.replace("_EventLog(events: events)", "_EventLog(events: filteredEvents)")
    
    with open(path, "w") as f:
        f.write(content)

rewrite()
