import re
with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f:
    text = f.read()

pattern = r"            kVSpacer8,\s*SelectableText\(\s*message\.payload\.isEmpty \? '\(empty\)' : message\.payload,\s*style: const TextStyle\(fontFamily: 'monospace', fontSize: 13\),\s*\),\s*\],\s*\),\s*\);\s*}\s*}"
replacement = """            kVSpacer8,
            SelectableText(
              message.payload.isEmpty ? '(empty)' : message.payload,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ],
        ),
      ),
    ));
  }
}"""
text = re.sub(pattern, replacement, text)
with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'w') as f:
    f.write(text)
