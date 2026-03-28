import re

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f:
    text = f.read()

# 1. Fix missing variables
if "String _filterEvent = '';" not in text:
    text = text.replace("String _filterTopic = '';", "String _filterTopic = '';\n  String _filterEvent = '';\n  late final TextEditingController _eventFilterCtrl;")

# 2. Fix initState
if "_eventFilterCtrl = TextEditingController" not in text:
    text = text.replace("_topicFilterCtrl = TextEditingController(text: _filterTopic);", "_topicFilterCtrl = TextEditingController(text: _filterTopic);\n    _eventFilterCtrl = TextEditingController(text: _filterEvent);")

# 3. Fix dispose
if "_eventFilterCtrl.dispose();" not in text:
    text = text.replace("_topicFilterCtrl.dispose();", "_topicFilterCtrl.dispose();\n    _eventFilterCtrl.dispose();")

# 5. Fix UI inside IndexedStack
index_stack_pattern = r"IndexedStack\(\s*index: _tabCtrl\.index,\s*children: \[\s*Padding\(\s*padding: kPh8v4,\s*child: Row\(\s*children: \[.*?kSizedBoxEmpty,\s*\],"

replacement = r"""IndexedStack(
          index: _tabCtrl.index,
          children: [
            Padding(
              padding: kPh8v4,
              child: Row(
                children: [
                  ADDropdownButton<int>(
                    value: _filterTypeIndex,
                    onChanged: (int? value) {
                      if (value != null) {
                        setState(() {
                          _filterTypeIndex = value;
                        });
                      }
                    },
                    values: const [(0, 'All'), (1, 'Sent'), (2, 'Received')],
                  ),
                  kHSpacer8,
                  Expanded(
                    child: TextField(
                      controller: _topicFilterCtrl,
                      onChanged: (v) => setState(() => _filterTopic = v),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Filter by topic...',
                        prefixIcon: const Icon(Icons.search, size: 16),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(borderRadius: kBorderRadius8),
                        suffixIcon: _topicFilterCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _topicFilterCtrl.clear();
                                  setState(() => _filterTopic = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: kPh8v4,
              child: TextField(
                controller: _eventFilterCtrl,
                onChanged: (v) => setState(() => _filterEvent = v),
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
                            setState(() => _filterEvent = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ],"""

text = re.sub(index_stack_pattern, replacement, text, flags=re.DOTALL)

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'w') as f:
    f.write(text)

