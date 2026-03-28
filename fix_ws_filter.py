import re

def rewrite():
    path = "lib/widgets/websocket/websocket_response_pane.dart"
    with open(path, "r") as f:
        content = f.read()

    # insert filteredEvents right before return Column
    if "final filteredEvents =" not in content:
        content = content.replace(
        "return Column(",
        """final filteredEvents = _filterEventString.isEmpty
          ? events
          : events.where((e) => e.description.toLowerCase().contains(_filterEventString.toLowerCase())).toList();

      return Column("""
        )

    with open(path, "w") as f:
        f.write(content)

rewrite()

