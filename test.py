with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f:
    text = f.read()

idx = text.find('SelectableText')
print(repr(text[idx:idx+200]))
