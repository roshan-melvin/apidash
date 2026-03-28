import re

def process(filepath):
    with open(filepath, 'r') as f:
        text = f.read()

    old_dec = """                        prefixIcon: const Icon(Icons.filter_list_rounded, size: 16),
                        hintText:"""

    new_dec = """                        prefixIcon: const Icon(Icons.filter_list_rounded, size: 16),
                        suffixIcon: (isChat ? _msgFilterCtrl.text : _eventFilterCtrl.text).isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  if (isChat) {
                                    _msgFilterCtrl.clear();
                                    setState(() => _filterString = '');
                                  } else {
                                    _eventFilterCtrl.clear();
                                    setState(() => _filterEventString = '');
                                  }
                                },
                              )
                            : null,
                        hintText:"""
    text = text.replace(old_dec, new_dec)
    with open(filepath, 'w') as f:
        f.write(text)

process('lib/widgets/websocket/websocket_response_pane.dart')
process('lib/widgets/grpc_response_pane.dart')
