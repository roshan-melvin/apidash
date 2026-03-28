import sys

def replace_lines():
    with open("lib/widgets/mqtt/mqtt_response_pane.dart", "r") as f:
        lines = f.readlines()
        
    start_idx = -1
    end_idx = -1
    for i, line in enumerate(lines):
        if "// ── Topic/Event filter" in line:
            start_idx = i
        if "// ── Tab content" in line:
            end_idx = i
            break
            
    if start_idx != -1 and end_idx != -1:
        new_lines = lines[:start_idx]
        new_lines.append("""        // ── Topic/Event filter ────────────────────────────
        AnimatedBuilder(
          animation: _tabCtrl,
          builder: (_, __) {
            final isChat = _tabCtrl.index == 0;
            return Padding(
              padding: kPh8v4,
              child: TextField(
                key: ValueKey('mqtt_filter_${_tabCtrl.index}'),
                initialValue: isChat ? _filterTopic : _filterEvent,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                  isDense: true,
                  hintText: isChat ? 'Filter by topic…' : 'Filter events…',
                  prefixIcon: const Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: kBorderRadius8,
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: kBorderRadius8,
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: (v) {
                  if (isChat) {
                    setState(() => _filterTopic = v);
                  } else {
                    setState(() => _filterEvent = v);
                  }
                },
              ),
            );
          },
        ),
""")
        new_lines.extend(lines[end_idx:])
        
        with open("lib/widgets/mqtt/mqtt_response_pane.dart", "w") as f:
            f.writelines(new_lines)
            
replace_lines()
