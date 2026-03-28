import re
with open('lib/services/grpc_service.dart', 'r') as f:
    text = f.read()

text = text.replace('connectionTimeout: const Duration(seconds: 5),', 'connectionTimeout: const Duration(seconds: 15),')
text = text.replace('await _channel!.getConnection().timeout(\n          const Duration(seconds: 5),\n          onTimeout: () => throw Exception(\'Connection timed out after 5 seconds. Check port and TLS settings.\'),\n        );', 'await _channel!.getConnection().timeout(\n          const Duration(seconds: 15),\n          onTimeout: () => throw Exception(\'Connection timed out after 15 seconds. Check port and TLS settings.\'),\n        );')
text = text.replace('timeout(const Duration(seconds: 5), onTimeout: () {\n          throw Exception(\'Server Reflection timed out after 5 seconds. Check port and TLS connection settings.\');\n        });', 'timeout(const Duration(seconds: 15), onTimeout: () {\n          throw Exception(\'Server Reflection timed out after 15 seconds. Check port and TLS connection settings.\');\n        });')

with open('lib/services/grpc_service.dart', 'w') as f:
    f.write(text)
