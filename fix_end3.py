with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f:
    text = f.read()

bad = "SelectableText(\n              message.payload.isEmpty ? '(empty)' : message.payload,\n              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),\n            ),\n          ],\n        ),\n      );\n    }\n  }"

good = "SelectableText(\n              message.payload.isEmpty ? '(empty)' : message.payload,\n              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),\n            ),\n          ],\n        ),\n      ),\n    ));\n  }\n}"

print(bad in text)
text = text.replace(bad, good)
with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'w') as f:
    f.write(text)
