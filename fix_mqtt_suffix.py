import re

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f:
    text = f.read()

# Replace prefixIcon section in mqtt
old_mqtt_dec = """                    prefixIcon: const Icon(
                      Icons.filter_list_rounded,
                      size: 18,
                    ),
                    border: OutlineInputBorder("""

new_mqtt_dec = """                    prefixIcon: const Icon(
                      Icons.filter_list_rounded,
                      size: 18,
                    ),
                    suffixIcon: (isChat ? _topicFilterCtrl.text : _eventFilterCtrl.text).isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              if (isChat) {
                                _topicFilterCtrl.clear();
                                setState(() => _filterTopic = '');
                              } else {
                                _eventFilterCtrl.clear();
                                setState(() => _filterEvent = '');
                              }
                            },
                          )
                        : null,
                    border: OutlineInputBorder("""

text = text.replace(old_mqtt_dec, new_mqtt_dec)
with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'w') as f:
    f.write(text)
