import re

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f:
    text = f.read()

old_tf = """                child: TextFormField(
                  key: ValueKey('mqtt_filter_${_tabCtrl.index}'),
                  initialValue: isChat ? _filterTopic : _filterEvent,"""

new_tf = """                child: TextFormField(
                  key: ValueKey('mqtt_filter_${_tabCtrl.index}'),
                  controller: isChat ? _topicFilterCtrl : _eventFilterCtrl,"""

text = text.replace(old_tf, new_tf)

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'w') as f:
    f.write(text)
