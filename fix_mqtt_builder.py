with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f:
    content = f.read()

start_index = content.find('AnimatedBuilder(')
end_index = content.find('Expanded(', start_index)
if start_index != -1 and end_index != -1:
    new_builder = """AnimatedBuilder(
            animation: _tabCtrl,
            builder: (_, __) {
              if (_tabCtrl.index == 0) {
                return Padding(
                  padding: kPh8v4,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Filter by topic...',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                            prefixIcon: const Icon(Icons.search, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: kBorderRadius8,
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: kBorderRadius8,
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (v) => setState(() => _filterTopic = v),
                        ),
                      ),
                      kHSpacer8,
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.filter_list_rounded),
                        tooltip: 'Filter by direction',
                        initialValue: _messageDirection,
                        onSelected: (val) => setState(() => _messageDirection = val),
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'all', child: Text('All Messages')),
                          PopupMenuItem(value: 'in', child: Text('Incoming Only')),
                          PopupMenuItem(value: 'out', child: Text('Outgoing Only')),
                        ],
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
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Filter events...',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                            prefixIcon: const Icon(Icons.search, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: kBorderRadius8,
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: kBorderRadius8,
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (v) => setState(() => _filterEvent = v),
                        ),
                      ),
                      kHSpacer8,
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.filter_list_rounded),
                        tooltip: 'Filter by type',
                        initialValue: _eventFilterType,
                        onSelected: (val) => setState(() => _eventFilterType = val),
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'all', child: Text('All Events')),
                          PopupMenuItem(value: 'success', child: Text('Success Only')),
                          PopupMenuItem(value: 'error', child: Text('Error Only')),
                        ],
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          // ── Tab content ─────────────────────────────────────────────────
          """

    content = content[:start_index] + new_builder + content[end_index:]
    with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'w') as f:
        f.write(content)
else:
    print('Failed to find indices')
