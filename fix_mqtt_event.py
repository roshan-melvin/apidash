import re

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f:
    content = f.read()

# Add _eventFilterType
content = re.sub(
    r"String _filterEvent = '';\n  String _messageDirection = 'all';",
    "String _filterEvent = '';\n  String _eventFilterType = 'all';\n  String _messageDirection = 'all';",
    content
)

# Update event filtering logic
new_event_filter = """
    var filteredEvents = events.where((e) {
      final typeName = e.type.name.toLowerCase();
      final isError = typeName.contains('error') || typeName.contains('connectionfailed');
      final isSuccess = typeName.contains('subscribe') || typeName.contains('connect') || typeName.contains('send') || typeName.contains('receive');
      
      if (_eventFilterType == 'error' && !isError) return false;
      if (_eventFilterType == 'success' && !isSuccess) return false;

      if (_filterEvent.isNotEmpty) {
        final query = _filterEvent.toLowerCase();
        final typeMatch = typeName.contains(query);
        final descMatch = e.description.toLowerCase().contains(query);
        final topicMatch = e.topic?.toLowerCase().contains(query) ?? false;
        if (!typeMatch && !descMatch && !topicMatch) return false;
      }
      return true;
    }).toList();
"""

content = re.sub(
    r"    var filteredEvents = _filterEvent\.isEmpty.*?\.toList\(\);",
    new_event_filter.strip(),
    content,
    flags=re.DOTALL
)

# Replace the textfield for events with row
new_event_textfield = """
              return Padding(
                padding: kPh8v4,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Filter events…',
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
"""

content = re.sub(
    r"              return Padding\([\s\S]*?onChanged: \(v\) => setState\(\(\) => _filterEvent = v\),\n                \),\n              \);",
    new_event_textfield.strip(),
    content
)

# Update topics white inside
content = re.sub(
    r"Theme\.of\(context\)\.colorScheme\.surface,",
    "Theme.of(context).colorScheme.surfaceContainerLowest,",
    content
)

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'w') as f:
    f.write(content)
