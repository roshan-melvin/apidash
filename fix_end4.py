import re
with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f: text = f.read()

pattern = r"SelectableText\(\s*message\.payload\.isEmpty \? '\(empty\)' : message\.payload,\s*style: const TextStyle\(fontFamily: 'monospace', fontSize: 13\),\s*\),\s*\],\s*\),\s*\);\s*}\s*}"
replacement = "SelectableText(\n              message.payload.isEmpty ? '(empty)' : message.payload,\n              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),\n            ),\n          ],\n        ),\n      ),\n    ));\n  }\n}"

text = re.sub(pattern, replacement, text)

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'w') as f: f.write(text)
