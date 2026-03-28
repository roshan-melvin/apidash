import re

with open("lib/widgets/grpc_response_pane.dart", "r") as f:
    text = f.read()

bad_str = """onSelectionChanged: (Set<int> newSelection) {
                      ref
                          .read(collectionStateNotifierProvider.notifier)
                          .updateGrpcModel(filterIndex: newSelection.first);
                    },"""

good_str = """onSelectionChanged: (Set<int> newSelection) {
                      setState(() {
                        _filterIndex = newSelection.first;
                      });
                    },"""

if bad_str in text:
    text = text.replace(bad_str, good_str)
    with open("lib/widgets/grpc_response_pane.dart", "w") as f:
        f.write(text)
    print("Fixed!")
else:
    print("bad_str not found")
