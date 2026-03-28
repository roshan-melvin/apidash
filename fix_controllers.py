import re

with open('lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_request_pane.dart', 'r') as f:
    text = f.read()

# remove controller logic
text = re.sub(r'  final TextEditingController _serviceCtrl = TextEditingController\(\);\n  final TextEditingController _methodCtrl = TextEditingController\(\);\n\n  String\? _lastId;\n\n  @override\n  void dispose\(\) {\n    _serviceCtrl\.dispose\(\);\n    _methodCtrl\.dispose\(\);\n    super\.dispose\(\);\n  }\n\n  void _updateControllers\(String selectedId, GrpcRequestModel model\) {\n    if \(_lastId != selectedId\) {\n      _serviceCtrl\.text = model\.serviceName;\n      _methodCtrl\.text = model\.methodName;\n      _lastId = selectedId;\n    }\n  }\n', '', text)
text = text.replace("    _updateControllers(selectedId!, requestModel.grpcRequestModel!);", "")

with open('lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_request_pane.dart', 'w') as f:
    f.write(text)

