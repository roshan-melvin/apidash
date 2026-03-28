import re

with open("lib/widgets/mqtt/mqtt_response_pane.dart", "r") as f:
    text = f.read()

bad_str = """    // Filter messages by topic if a filter is set
    final filtered = _filterTopic.isEmpty
        ? typeFiltered
        : typeFiltered.where((m) => m.topic.contains(_filterTopic)).toList();"""

good_str = """    // Filter messages by topic if a filter is set
    final filtered = _filterTopic.isEmpty
        ? typeFiltered
        : typeFiltered.where((m) => m.topic.contains(_filterTopic)).toList();

    final filteredEvents = _filterEventString.isEmpty
        ? events
        : events
            .where((e) =>
                e.description.toLowerCase().contains(_filterEventString.toLowerCase()))
            .toList();"""

if bad_str in text:
    text = text.replace(bad_str, good_str)
    with open("lib/widgets/mqtt/mqtt_response_pane.dart", "w") as f:
        f.write(text)
    print("Fixed mqtt!")
else:
    print("bad_str not found in mqtt")
