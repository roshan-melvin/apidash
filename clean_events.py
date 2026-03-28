import re

files = {
    'websocket': 'lib/widgets/websocket/websocket_response_pane.dart',
    'grpc': 'lib/widgets/grpc_response_pane.dart',
    'mqtt': 'lib/widgets/mqtt/mqtt_response_pane.dart'
}

for key, path in files.items():
    with open(path, 'r') as f:
        text = f.read()

    # remove variable declarations
    text = re.sub(r"String _filterEventString = '';\n\s*late final TextEditingController _msgFilterCtrl;\n\s*late final TextEditingController _eventFilterCtrl;\n", "", text)
    text = re.sub(r"String _filterEvent = '';\n\s*int _filterTypeIndex", "int _filterTypeIndex", text)
    text = re.sub(r"late final TextEditingController _eventFilterCtrl;\n", "", text)
    text = re.sub(r"_eventFilterCtrl = TextEditingController.*?;", "", text)
    text = re.sub(r"_eventFilterCtrl\.dispose\(\);", "", text)
    
    # remove filteredEvents logic
    text = re.sub(r"final filteredEvents = .*?\.toList\(\);", "", text, flags=re.DOTALL)
    
    # revert mapping inside TabBarView
    text = text.replace("filteredEvents", "events")

    with open(path, 'w') as f:
        f.write(text)

print("Cleaned up unused event filter variables")
