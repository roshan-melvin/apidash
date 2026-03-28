import re
with open('lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_request_pane.dart', 'r') as f:
    text = f.read()
text = text.replace("import 'package:apidash/models/models.dart';\n", "")
with open('lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_request_pane.dart', 'w') as f:
    f.write(text)

