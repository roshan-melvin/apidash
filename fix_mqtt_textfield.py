import re

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f:
    text = f.read()

text = text.replace(
    "initialValue: isChat ? _filterTopic : _filterEvent,",
    "controller: isChat ? _topicFilterCtrl : _eventFilterCtrl,"
)

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'w') as f:
    f.write(text)
