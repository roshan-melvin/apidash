import re

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f:
    content = f.read()

new_event_textfield = """
              return Padding(
                padding: kPh8v4,
                child: TextField(
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Filter events…',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
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
              );
"""

content = re.sub(
    r"              return Padding\(\n                padding: kPh8v4,\n                child: TextField\([\s\S]*?onChanged: \(v\) => setState\(\(\) => _filterEvent = v\),\n                \),\n              \);",
    new_event_textfield.strip(),
    content
)

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'w') as f:
    f.write(content)
