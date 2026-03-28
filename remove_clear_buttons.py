import re

def fix(path):
    with open(path, 'r') as f:
        content = f.read()

    # Find the Elevated button block
    # from Elevated... to ,...
    # It's better to just regex it out
    pattern = re.compile(r'ElevatedButton\.icon\(\s*onPressed: \(\) \{.*?elevation: 0,\s*\),\s*\),', re.DOTALL)
    content = pattern.sub('', content)

    # I also wrote `if (isChat) kHSpacer8,` right before it in WS
    content = content.replace("if (isChat) kHSpacer8,", "")
    # In GRPC I wrote `kHSpacer8,\n                  ElevatedButton`
    content = content.replace("kHSpacer8,\n                  \n                ],", "]\n              ),")
    content = content.replace("kHSpacer8,\n\n                ],", "]\n              ),")

    # In GRPC I actually had:
    #                   kHSpacer8,
    #                   ElevatedButton.icon(
    pattern2 = re.compile(r'kHSpacer8,\s*\]', re.DOTALL)
    content = pattern2.sub(']', content)

    with open(path, 'w') as f:
        f.write(content)

fix('lib/widgets/websocket/websocket_response_pane.dart')
fix('lib/widgets/grpc_response_pane.dart')
