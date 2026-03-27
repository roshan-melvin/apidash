import re

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/details_card/response_pane.dart', 'r') as f:
    text = f.read()

import_str = "import 'package:apidash/widgets/websocket/websocket_response_pane.dart';"
text = text.replace(import_str, import_str + "\nimport 'package:apidash/widgets/grpc_response_pane.dart';")

router_str = '''    if (apiType == APIType.websocket) {
      return const WebSocketResponsePane();
    }'''
text = text.replace(router_str, router_str + '''\n    if (apiType == APIType.grpc) {
      return const GrpcResponsePane();
    }''')

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/details_card/response_pane.dart', 'w') as f:
    f.write(text)
