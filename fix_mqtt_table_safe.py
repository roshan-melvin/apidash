import re

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/details_card/request_pane/mqtt/mqtt_request_pane.dart', 'r') as f:
    text = f.read()

# 1. Replace columns
columns_pattern = r"columns: const \[\s*DataColumn2\(\s*label:\s*Text\(\s*'Topic'.*?DataColumn2\(label: const Text\(''\), fixedWidth: 36\),\s*\]"
new_columns = """columns: const [
                  DataColumn2(
                    label: Text(kNameCheckbox),
                    fixedWidth: 30,
                  ),
                  DataColumn2(
                    label: Text(
                      'Topic',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn2(
                    label: Text(
                      'QoS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    fixedWidth: 60,
                  ),
                  DataColumn2(
                    label: Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn2(label: const Text(''), fixedWidth: 36),
                ]"""

text = re.sub(columns_pattern, new_columns, text, flags=re.DOTALL)

# 2. Replace rows
rows_pattern = r"rows: topics\.isEmpty.*?(?=\s*\),\s*\),\s*\),\s*Align\()"
new_rows = """rows: List.generate(topics.length + 1, (i) {
                        bool isLast = i == topics.length;
                        final t = isLast ? kMQTTTopicEmptyModel : topics[i];
                        return DataRow(
                          cells: [
                            DataCell(
                              ADCheckBox(
                                keyId: "mqtt-topic-sub-$i",
                                value: t.subscribe,
                                onChanged: isLast ? null : (v) => onUpdate(i, t.copyWith(subscribe: v ?? false)),
                                colorScheme: Theme.of(context).colorScheme,
                              ),
                            ),
                            DataCell(
                              TextFormField(
                                initialValue: t.topic,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'home/sensor',
                                ),
                                onChanged: (v) =>
                                    onUpdate(i, t.copyWith(topic: v)),
                              ),
                            ),
                            DataCell(
                              DropdownButton<int>(
                                value: t.qos,
                                underline: const SizedBox.shrink(),
                                items: const [
                                  DropdownMenuItem(value: 0, child: Text('0')),
                                  DropdownMenuItem(value: 1, child: Text('1')),
                                  DropdownMenuItem(value: 2, child: Text('2')),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    onUpdate(i, t.copyWith(qos: v));
                                  }
                                },
                              ),
                            ),
                            DataCell(
                              TextFormField(
                                initialValue: t.description,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Add description',
                                ),
                                onChanged: (v) =>
                                    onUpdate(i, t.copyWith(description: v)),
                              ),
                            ),
                            DataCell(
                              InkWell(
                                onTap: isLast ? null : () => onDelete(i),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    hoverColor: kColorTransparent,
                                    splashColor: kColorTransparent,
                                    highlightColor: kColorTransparent,
                                  ),
                                  child: Icon(
                                    Icons.remove_circle,
                                    size: 16,
                                    color: isLast
                                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                                        : Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      })"""

text = re.sub(rows_pattern, new_rows, text, flags=re.DOTALL)

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/details_card/request_pane/mqtt/mqtt_request_pane.dart', 'w') as f:
    f.write(text)

