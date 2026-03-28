with open('lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_service_def.dart', 'r') as f:
    text = f.read()

text = text.replace("import 'package:apidash/models/models.dart';\n", "")
text = text.replace(".withOpacity(0.5)", ".withValues(alpha: 0.5)")
text = text.replace(".withOpacity(0.7)", ".withValues(alpha: 0.7)")

with open('lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_service_def.dart', 'w') as f:
    f.write(text)

