import re

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f:
    text = f.read()

new_block = """        // ── Topic/Event filter ────────────────────────────
        AnimatedBuilder(
          animation: _tabCtrl,
          builder: (_, __) {
            return Padding(
              padding: kPh8v4,
              child: IndexedStack(
                index: _tabCtrl.index,
                children: [
                  TextFormField(
                    controller: _topicFilterCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                      isDense: true,
                      hintText: 'Type to filter by topic…',
                      prefixIcon: const Icon(Icons.filter_list_rounded, size: 18),
                      suffixIcon: _topicFilterCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _topicFilterCtrl.clear();
                                setState(() => _filterTopic = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: kBorderRadius8,
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: kBorderRadius8,
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (v) {
                      setState(() => _filterTopic = v);
                    },
                  ),
                  TextFormField(
                    controller: _eventFilterCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                      isDense: true,
                      hintText: 'Type to filter events…',
                      prefixIcon: const Icon(Icons.filter_list_rounded, size: 18),
                      suffixIcon: _eventFilterCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _eventFilterCtrl.clear();
                                setState(() => _filterEvent = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: kBorderRadius8,
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: kBorderRadius8,
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (v) {
                      setState(() => _filterEvent = v);
                    },
                  ),
                ],
              ),
            );
          },
        ),"""

pattern = re.compile(r"// ── Topic/Event filter ────────────────────────────\n\s*AnimatedBuilder\(.*?onChanged: \(v\) \{.*?\},\n\s*\),\n\s*\);\n\s*\},\n\s*\),", re.DOTALL)
text = pattern.sub(new_block, text)

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'w') as f:
    f.write(text)
