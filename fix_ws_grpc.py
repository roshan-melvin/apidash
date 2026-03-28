import re

def fix_ws():
    with open('lib/widgets/websocket/websocket_response_pane.dart', 'r') as f:
        content = f.read()

    # Add _filterEventString State variable
    if "String _filterEventString = '';" not in content:
        content = content.replace("String _filterString = '';", "String _filterString = '';\n  String _filterEventString = '';")

    # Update Widget build to filter events
    old_filtered = '''
    final inCount = messages.where((m) => m.isIncoming).length;
    final outCount = messages.where((m) => !m.isIncoming).length;

    final filtered = _filterString.isEmpty
        ? messages
        : messages
            .where((m) => m.data.toLowerCase().contains(_filterString.toLowerCase()))
            .toList();'''
    
    new_filtered = '''
    final inCount = messages.where((m) => m.isIncoming).length;
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

    # Update the AnimatedBuilder to show the proper filter input
    old_builder = '''          AnimatedBuilder(
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
                              filled: true,
                              fillColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLowest,
                              prefixIcon: const Icon(Icons.filter_list_rounded, size: 16),
                              hintText: 'Filter payload...',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: kBorderRadius8,
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: kBorderRadius8,
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ),
                          ),
                        ),
                        kHSpacer8,
                        ElevatedButton.icon(
                          onPressed: () {
                            ref
                                .read(collectionStateNotifierProvider.notifier)
                                .clearWebSocketMessages(selectedId);
                            ref
                                .read(collectionStateNotifierProvider.notifier)
                                .clearWebSocketEvents(selectedId);
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurface,
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),'''

    new_builder = '''          AnimatedBuilder(
            animation: _tabCtrl,
            builder: (_, __) => Padding(
              padding: kPh8v4,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: ValueKey('ws_filter_${_tabCtrl.index}'),
                      initialValue: _tabCtrl.index == 0 ? _filterString : _filterEventString,
                      onChanged: (v) {
                        if (_tabCtrl.index == 0) {
                          setState(() => _filterString = v);
                        } else {
                          setState(() => _filterEventString = v);
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                        prefixIcon: const Icon(Icons.filter_list_rounded, size: 18),
                        hintText: _tabCtrl.index == 0 ? 'Filter payload...' : 'Filter events...',
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
            ),
          ),'''
          
    if "ws_filter_" not in content:
        # Since text matching can be tricky with indentation, we'll use regex or replace blocks that are definitely there.
        # But wait, AnimatedBuilder is big. Let's just do a manual replace.
        pass
