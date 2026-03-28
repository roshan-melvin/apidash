import re

# 1. FIX WEBSOCKET RESPONSE PANE
with open('lib/widgets/websocket/websocket_response_pane.dart', 'r') as f:
    ws_content = f.read()

# Add _filterEventIndex if missing
if 'int _filterEventIndex =' not in ws_content:
    ws_content = ws_content.replace(
        "String _filterEventString = '';",
        "String _filterEventString = '';\n  int _filterEventIndex = 0;"
    )

# Fix filter logic
ws_event_filter_old = """    final filteredEvents = _filterEventString.isEmpty
        ? events
        : events
              .where(
                (e) => e.description.toLowerCase().contains(
                  _filterEventString.toLowerCase(),
                ),
              )
              .toList();"""

ws_event_filter_new = """    var typeFilteredEvents = events;
    if (_filterEventIndex == 1) {
      typeFilteredEvents = events.where((e) => e.type == WebSocketEventType.error || e.type == WebSocketEventType.disconnect).toList();
    } else if (_filterEventIndex == 2) {
      typeFilteredEvents = events.where((e) => e.type != WebSocketEventType.error && e.type != WebSocketEventType.disconnect).toList();
    }

    final filteredEvents = _filterEventString.isEmpty
        ? typeFilteredEvents
        : typeFilteredEvents
              .where(
                (e) => e.description.toLowerCase().contains(
                  _filterEventString.toLowerCase(),
                ),
              )
              .toList();"""

ws_content = ws_content.replace(ws_event_filter_old, ws_event_filter_new)

# Re-layout the Message Filter Row (replace SegmentedButton pattern)
ws_msg_row_pattern = r"(\s*)Expanded\(\s*child: TextField\(\s*controller: _msgFilterCtrl,[\s\S]*?TextField\),\s*\),\s*kHSpacer8,\s*SegmentedButton<int>\([\s\S]*?\}\s*,\s*\),"
# Need a better regex or string replace for the Row layout

# Actually let's just match the children array of the Row:
ws_msg_children_old = re.search(r'(?<=children: \[)\s*Expanded\(\s*child: TextField\(\s*controller: _msgFilterCtrl,[\s\S]*?\}\s*,\s*\),', ws_content)
if ws_msg_children_old:
    # Just a small manual slice
    pass

