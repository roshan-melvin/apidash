import re

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f:
    text = f.read()

pattern = r"// Filter messages by topic if a filter is set\s*\n\s*final filtered = _filterTopic\.isEmpty\s*\n\s*\?\s*messages\s*\n\s*:\s*messages\.where\(\(m\) => m\.topic\.contains\(_filterTopic\)\)\.toList\(\);"

replacement = r"""// Filter messages by type (All, Sent, Received)
    var typeFiltered = messages;
    if (_filterTypeIndex == 1) {
      typeFiltered = messages.where((m) => !m.isIncoming).toList();
    } else if (_filterTypeIndex == 2) {
      typeFiltered = messages.where((m) => m.isIncoming).toList();
    }

    // Filter messages by topic if a filter is set
    final filtered = _filterTopic.isEmpty
        ? typeFiltered
        : typeFiltered.where((m) => m.topic.contains(_filterTopic)).toList();"""

text = re.sub(pattern, replacement, text, flags=re.DOTALL)

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'w') as f:
    f.write(text)
print("MQTT filter fixed")

