import os
import re

def rewrite_mqtt():
    path = "lib/widgets/mqtt/mqtt_response_pane.dart"
    with open(path, "r") as f:
        content = f.read()

    # Let's replace the AnimatedBuilder with something very safe
    pattern = re.compile(r'// ── Topic/Event filter ────────────────────────────\n\s*AnimatedBuilder\(.*?// ── Tab content ─────────────────────────────────────────────────', re.DOTALL)
    
    new_builder = '''// ── Topic/Event filter ────────────────────────────
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
        // ── Tab content ─────────────────────────────────────────────────'''
    
    content = pattern.sub(new_builder, content)
    with open(path, "w") as f:
        f.write(content)

rewrite_mqtt()
print("Done MQTT")
