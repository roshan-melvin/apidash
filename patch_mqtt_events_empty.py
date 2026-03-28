path = 'lib/widgets/mqtt/mqtt_response_pane.dart'
with open(path, 'r') as f:
    text = f.read()

old = """                // Event log
                events.isEmpty
                    ? const _EmptyState(
                        icon: Icons.article_outlined,
                        label: 'No events yet',
                      )
                    : _EventList(events: filteredEvents),"""

new = """                // Event log
                events.isEmpty && _filterEvent.isEmpty
                    ? const _EmptyState(
                        icon: Icons.article_outlined,
                        label: 'No events yet',
                      )
                    : filteredEvents.isEmpty
                        ? const _EmptyState(
                            icon: Icons.article_outlined,
                            label: 'No events matching filter',
                          )
                        : _EventList(events: filteredEvents),"""

if old in text:
    text = text.replace(old, new)
else:
    print('Not found')
with open(path, 'w') as f:
    f.write(text)
