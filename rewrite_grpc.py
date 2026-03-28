import re

with open('lib/widgets/grpc_response_pane.dart', 'r') as f:
    text = f.read()

# 1. Fix missing variables
if "String _filterEventString = '';" not in text:
    text = text.replace("String _filterString = '';", "String _filterString = '';\n  String _filterEventString = '';\n  late final TextEditingController _msgFilterCtrl;\n  late final TextEditingController _eventFilterCtrl;")

# 2. Fix initState
if "_eventFilterCtrl = TextEditingController" not in text:
    text = text.replace("_msgFilterCtrl = TextEditingController(text: _filterString);", "_msgFilterCtrl = TextEditingController(text: _filterString);\n    _eventFilterCtrl = TextEditingController(text: _filterEventString);")

# 3. Fix dispose
if "_eventFilterCtrl.dispose();" not in text:
    text = text.replace("_msgFilterCtrl.dispose();", "_msgFilterCtrl.dispose();\n    _eventFilterCtrl.dispose();")

# 4. Filter events logic
if "final filteredEvents" not in text:
    text = text.replace("final filtered = _filterString.isEmpty", """final filteredEvents = _filterEventString.isEmpty
        ? events
        : events
              .where(
                (e) => e.description.toLowerCase().contains(
                  _filterEventString.toLowerCase(),
                ),
              )
              .toList();

    final filtered = _filterString.isEmpty""")

# 5. Fix UI inside IndexedStack
index_stack_pattern = r"IndexedStack\(\s*index: _tabCtrl\.index,\s*children: \[\s*Padding\(\s*padding: kPh8v4,\s*child: Row\(\s*children: \[.*?kSizedBoxEmpty,\s*\],"

replacement = r"""IndexedStack(
          index: _tabCtrl.index,
          children: [
            Padding(
              padding: kPh8v4,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgFilterCtrl,
                      onChanged: (v) => setState(() => _filterString = v),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Filter payload...',
                        prefixIcon: const Icon(Icons.search, size: 16),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(borderRadius: kBorderRadius8),
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
                  ),
                  kHSpacer8,
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 0,
                        label: Text('All', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment<int>(
                        value: 2, // received
                        label: Row(
                          children: [
                            Icon(Icons.arrow_downward, size: 12),
                            SizedBox(width: 4),
                            Text('In', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      ButtonSegment<int>(
                        value: 1, // sent
                        label: Row(
                          children: [
                            Icon(Icons.arrow_upward, size: 12),
                            SizedBox(width: 4),
                            Text('Out', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                    selected: {filterIndex},
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                    onSelectionChanged: (Set<int> newSelection) {
                      ref
                          .read(collectionStateNotifierProvider.notifier)
                          .updateGrpcModel(
                            filterIndex: newSelection.first,
                          );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: kPh8v4,
              child: TextField(
                controller: _eventFilterCtrl,
                onChanged: (v) => setState(() => _filterEventString = v),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Filter events...',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(borderRadius: kBorderRadius8),
                  suffixIcon: _eventFilterCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _eventFilterCtrl.clear();
                            setState(() => _filterEventString = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ],"""

text = re.sub(index_stack_pattern, replacement, text, flags=re.DOTALL)

with open('lib/widgets/grpc_response_pane.dart', 'w') as f:
    f.write(text)

