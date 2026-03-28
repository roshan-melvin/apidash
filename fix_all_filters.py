import re

def fix_file(filename):
    with open(filename, 'r') as f:
        text = f.read()

    # Find the InputDecoration block or just replace the borders
    # Let's replace the colorScheme.outlineVariant for enabledBorder and border
    # to colorScheme.surfaceContainerHighest
    
    # We will replace these specific lines:
    # borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    text = text.replace(
        "borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),",
        "borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),"
    )
    
    with open(filename, 'w') as f:
        f.write(text)

fix_file('lib/widgets/mqtt/mqtt_response_pane.dart')
fix_file('lib/widgets/websocket/websocket_response_pane.dart')
fix_file('lib/widgets/grpc_response_pane.dart')
