import re

def process_file(filename, update_func):
    with open(filename, 'r') as f:
        content = f.read()
    content = update_func(content)
    with open(filename, 'w') as f:
        f.write(content)

def update_ws(content):
    # Add _filterEventIndex if missing
    if 'int _filterEventIndex =' not in content:
        content = content.replace(
            "String _filterEventString = '';",
            "String _filterEventString = '';\n  int _filterEventIndex = 0;"
        )

    # Fix logic
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
    content = content.replace(ws_event_filter_old, ws_event_filter_new)

    # Replace Message Row
    # Find the entire children array of the Row inside the first step of IndexedStack
    # It starts with Expanded(child: TextField(controller: _msgFilterCtrl...
    msg_replace_pattern = r"(Expanded\(\s*child: TextField\(\s*controller: _msgFilterCtrl,[\s\S]*?\}\s*,\s*\)\s*:\s*null,\s*\),\s*\),\s*\),\s*kHSpacer8,\s*SegmentedButton<int>\([\s\S]*?\}\s*,\s*\),)"
    
    msg_replacement = """ADDropdownButton<int>(
                    value: filterIndex,
                    onChanged: (int? value) {
                      if (value != null) {
                        ref
                            .read(collectionStateNotifierProvider.notifier)
                            .updateWebSocketModel(filterIndex: value);
                      }
                    },
                    values: const [(0, 'All'), (1, 'Sent'), (2, 'Received')],
                  ),
                  kHSpacer8,
                  Expanded(
                    child: TextField(
                      controller: _msgFilterCtrl,
                      onChanged: (v) => setState(() => _filterString = v),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.light
                            ? Colors.white
                            : null,
                        isDense: true,
                        hintText: 'Filter payload...',
                        prefixIcon: const Icon(Icons.search, size: 16),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        suffixIcon: _msgFilterCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _msgFilterCtrl.clear();
                                  setState(() => _filterString = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),"""
    content = re.sub(msg_replace_pattern, msg_replacement, content)

    # Replace Event Row
    # Current Event tab only has a TextField. We need to wrap it in a Row and add ADDropdownButton
    # Wait, the current is:
    # Padding(
    #   padding: kPh8v4,
    #   child: TextField(
    #     controller: _eventFilterCtrl,
    
    event_replace_pattern = r"(child:\s*)(TextField\(\s*controller: _eventFilterCtrl,[\s\S]*?\}\s*,\s*\)\s*:\s*null,\s*\),\s*\),)"
    
    event_replacement = r"""\1Row(
                children: [
                  ADDropdownButton<int>(
                    value: _filterEventIndex,
                    onChanged: (int? value) {
                      if (value != null) {
                        setState(() {
                          _filterEventIndex = value;
                        });
                      }
                    },
                    values: const [(0, 'All'), (1, 'Error'), (2, 'No Error')],
                  ),
                  kHSpacer8,
                  Expanded(
                    child: \2
                  ),
                ],
              ),"""
    content = re.sub(event_replace_pattern, event_replacement, content)

    return content

process_file('lib/widgets/websocket/websocket_response_pane.dart', update_ws)

