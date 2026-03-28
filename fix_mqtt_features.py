import re
import sys

path = 'apidash/lib/widgets/mqtt/mqtt_response_pane.dart'
try:
    with open(path, 'r') as f:
        content = f.read()
except FileNotFoundError:
    path = 'lib/widgets/mqtt/mqtt_response_pane.dart'
    with open(path, 'r') as f:
        content = f.read()

# 1. Add `_filterEvent` to _MQTTResponsePaneState
if 'String _filterEvent =' not in content:
    content = content.replace("String _filterTopic = '';", "String _filterTopic = '';\n  String _filterEvent = '';")

# 2. Add `filteredEvents` logic
filtered_events_logic = """    final filtered = _filterTopic.isEmpty
        ? messages
        : messages.where((m) => m.topic.contains(_filterTopic)).toList();"""
if 'final filteredEvents =' not in content:
    content = content.replace(filtered_events_logic, filtered_events_logic + """\n\n    final filteredEvents = _filterEvent.isEmpty\n        ? events\n        : events.where((e) => e.description.toLowerCase().contains(_filterEvent.toLowerCase())).toList();""")

# 3. Replace AnimatedBuilder for both Messages and Events tab with the correct decoration
old_animated_builder = """          AnimatedBuilder(
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
          ),"""

new_animated_builder = """          AnimatedBuilder(
            animation: _tabCtrl,
            builder: (_, __) => Padding(
              padding: kPh8v4,
              child: TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                  isDense: true,
                  hintText: _tabCtrl.index == 0 ? 'Filter by topic…' : 'Filter events…',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                  ),
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
                    vertical: 6,
                  ),
                ),
                onChanged: (v) {
                  if (_tabCtrl.index == 0) {
                    setState(() => _filterTopic = v);
                  } else {
                    setState(() => _filterEvent = v);
                  }
                },
              ),
            ),
          ),"""

content = content.replace(old_animated_builder, new_animated_builder)

# 4. Use `filteredEvents` in `_EventList`
content = content.replace("_EventList(events: events),", "_EventList(events: filteredEvents),")
content = content.replace("events.isEmpty\n                    ? const _EmptyState(\n                        icon: Icons.article_outlined,\n                        label: 'No events yet',\n                      )\n                    : _EventList(events: events)", "filteredEvents.isEmpty\n                    ? const _EmptyState(\n                        icon: Icons.article_outlined,\n                        label: 'No events yet',\n                      )\n                    : _EventList(events: filteredEvents)")

# 5. Fix Event Color Coding in _EventList
# Need to find `DataCell(` with `Container` that has `e.type.name.toUpperCase()`
event_list_color_logic_regex = r"""DataCell\(\s*Container\(\s*padding: const EdgeInsets.symmetric\(horizontal: 6, vertical: 2\),\s*decoration: BoxDecoration\(\s*color: clr\.surfaceContainerHighest,\s*borderRadius: kBorderRadius4,\s*\),\s*child: Text\(\s*e\.type\.name\.toUpperCase\(\),\s*style: const TextStyle\(fontSize: 10\),\s*\),\s*\),\s*\)"""

replacement_color_logic = """DataCell(
                Builder(
                  builder: (context) {
                    final typeName = e.type.name.toLowerCase();
                    final isPositive = typeName.contains('connect') || typeName.contains('success');
                    final isNegative = typeName.contains('error') || typeName.contains('close') || typeName.contains('disconnect');
                    
                    Color bgColor = clr.surfaceContainerHighest;
                    Color textColor = clr.onSurface;
                    
                    if (isPositive) {
                      bgColor = clr.primaryContainer;
                      textColor = clr.onPrimaryContainer;
                    } else if (isNegative) {
                      bgColor = clr.errorContainer;
                      textColor = clr.onErrorContainer;
                    }
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: kBorderRadius4,
                      ),
                      child: Text(
                        e.type.name.toUpperCase(),
                        style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                ),
              )"""

content = re.sub(event_list_color_logic_regex, replacement_color_logic, content)

with open(path, 'w') as f:
    f.write(content)
