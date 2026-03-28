import re

with open('lib/widgets/grpc_response_pane.dart', 'r') as f:
    text = f.read()

# Fix `filterIndex` -> `_filterIndex` and update state
text = text.replace("selected: {filterIndex},", "selected: {_filterIndex},")
text = text.replace("""                    onSelectionChanged: (Set<int> newSelection) {
                      ref
                          .read(collectionStateNotifierProvider.notifier)
                          .updateGrpcModel(
                            filterIndex: newSelection.first,
                          );
                    },""", """                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() {
                        _filterIndex = newSelection.first;
                      });
                    },""")

# Fix unused filteredEvents
text = text.replace("_EventLog(events: events),", "_EventLog(events: filteredEvents),")

with open('lib/widgets/grpc_response_pane.dart', 'w') as f:
    f.write(text)

