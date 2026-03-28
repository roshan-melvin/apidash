import re

def rewrite():
    path = "lib/widgets/mqtt/mqtt_response_pane.dart"
    with open(path, "r") as f:
        content = f.read()

    # Update logic for case insensitive
    content = content.replace(
        "messages.where((m) => m.topic.contains(_filterTopic)).toList();",
        "messages.where((m) => m.topic.toLowerCase().contains(_filterTopic.toLowerCase())).toList();"
    )

    with open(path, "w") as f:
        f.write(content)

rewrite()
