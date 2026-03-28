import re

with open('lib/widgets/grpc_response_pane.dart', 'r') as f:
    text = f.read()

new_block = """        AnimatedBuilder(
          animation: _tabCtrl,
          builder: (_, __) {
            return Padding(
              padding: kPh8v4,
              child: IndexedStack(
                index: _tabCtrl.index,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _msgFilterCtrl,
                          onChanged: (v) {
                            setState(() => _filterString = v);
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                            prefixIcon: const Icon(Icons.filter_list_rounded, size: 16),
                            suffixIcon: _msgFilterCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _msgFilterCtrl.clear();
                                      setState(() => _filterString = '');
                                    },
                                  )
                                : null,
                            hintText: 'Filter payload...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: kBorderRadius8,
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: kBorderRadius8,
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _eventFilterCtrl,
                          onChanged: (v) {
                            setState(() => _filterEventString = v);
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                            prefixIcon: const Icon(Icons.filter_list_rounded, size: 16),
                            suffixIcon: _eventFilterCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _eventFilterCtrl.clear();
                                      setState(() => _filterEventString = '');
                                    },
                                  )
                                : null,
                            hintText: 'Filter events...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: kBorderRadius8,
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: kBorderRadius8,
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),"""

pattern = re.compile(r"        AnimatedBuilder\(\n\s*animation: _tabCtrl,\n\s*builder: \(_, __\) \{.*?\)\,\n\s*\)\,\n\s*\)\,\n\s*\]\n\s*\)\,\n\s*\)\;\n\s*\}\,\n\s*\)\,", re.DOTALL)
text = pattern.sub(new_block, text)

with open('lib/widgets/grpc_response_pane.dart', 'w') as f:
    f.write(text)
