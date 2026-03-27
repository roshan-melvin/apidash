import sys

content = open('lib/models/grpc_request_model.dart', 'r').read()
content = content.replace("import 'package:freezed_annotation/freezed_annotation.dart';\n", "")
open('lib/models/grpc_request_model.dart', 'w').write(content)

