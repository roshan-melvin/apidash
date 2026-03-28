import re

def fix_fields(filename):
    with open(filename, 'r') as f:
        content = f.read()

    # The border spans lines:
    content = re.sub(
        r"border:\s*OutlineInputBorder\(\s*borderRadius:\s*kBorderRadius8,\s*\),",
        """filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: kBorderRadius8,
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: kBorderRadius8,
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                            ),""",
        content
    )
    with open(filename, 'w') as f:
        f.write(content)

fix_fields('lib/widgets/websocket/websocket_response_pane.dart')
fix_fields('lib/widgets/grpc_response_pane.dart')

