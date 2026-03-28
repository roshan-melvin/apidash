import re

path = 'lib/widgets/websocket/websocket_response_pane.dart'
with open(path, 'r') as f:
    text = f.read()

old_event = """class _EventLog extends StatelessWidget {
  const _EventLog({required this.events});
  final List<WebSocketEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const Center(child: Text('No events.'));

    final clr = Theme.of(context).colorScheme;
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      headingRowHeight: 0,
      columns: const [
        DataColumn2(label: Text(''), fixedWidth: 100),
        DataColumn2(label: Text(''), fixedWidth: 100),
        DataColumn2(label: Text('')),
      ],
      rows: events.reversed.map((e) {
        return DataRow(
          cells: [
            DataCell(Text(_timeFmt.format(e.timestamp),
                style: TextStyle(color: clr.outline, fontSize: 12))),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: clr.surfaceContainerHighest,
                  borderRadius: kBorderRadius4,
                ),
                child: Text(e.type.name.toUpperCase(),
                    style: const TextStyle(fontSize: 10)),
              ),
            ),
            DataCell(
              Text(e.description, style: const TextStyle(fontSize: 12)),
            ),
          ],
        );
      }).toList(),
    );
  }
}"""

new_event = """class _EventLog extends StatelessWidget {
  const _EventLog({required this.events});
  final List<WebSocketEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const Center(child: Text('No events.'));

    final clr = Theme.of(context).colorScheme;
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      headingRowHeight: 0,
      columns: const [
        DataColumn2(label: Text(''), fixedWidth: 100),
        DataColumn2(label: Text(''), fixedWidth: 100),
        DataColumn2(label: Text('')),
      ],
      rows: events.reversed.map((e) {
        final isError = e.type.name.toLowerCase() == 'error';
        final isPositive = e.type.name.toLowerCase() == 'connect';
        return DataRow(
          cells: [
            DataCell(Text(_timeFmt.format(e.timestamp),
                style: TextStyle(color: clr.outline, fontSize: 12))),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isError
                      ? clr.errorContainer
                      : isPositive
                          ? Colors.green.withOpacity(0.2)
                          : clr.surfaceContainerHighest,
                  borderRadius: kBorderRadius4,
                ),
                child: Text(
                  e.type.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: isError
                        ? clr.onErrorContainer
                        : isPositive
                            ? Colors.green.shade800
                            : clr.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            DataCell(
              Text(e.description, style: const TextStyle(fontSize: 12)),
            ),
          ],
        );
      }).toList(),
    );
  }
}"""

text = text.replace(old_event, new_event)

with open(path, 'w') as f:
    f.write(text)

