import sys

content = open('lib/services/grpc_service.dart', 'r').read()
content = content.replace("import 'package:logger/logger.dart';", "import 'package:flutter/foundation.dart';")
content = content.replace("final _log = Logger();\n", "")
content = content.replace("_log.e(", "debugPrint(")
open('lib/services/grpc_service.dart', 'w').write(content)

