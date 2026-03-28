import re
with open('lib/services/grpc_service.dart', 'r') as f:
    text = f.read()

text = text.replace('connectionTimeout: const Duration(seconds: 10),', 'connectionTimeout: const Duration(seconds: 5),')
text = text.replace('const Duration(seconds: 10),\n          onTimeout: () => throw Exception(\'Connection timed out after 10 seconds. Check port and TLS settings.\'),', 'const Duration(seconds: 5),\n          onTimeout: () => throw Exception(\'Connection timed out after 5 seconds. Check port and TLS settings.\'),')
text = text.replace('timeout(const Duration(seconds: 15), onTimeout: () {\n          throw Exception(\'Server Reflection timed out after 15 seconds. Check port and TLS connection settings.\');', 'timeout(const Duration(seconds: 5), onTimeout: () {\n          throw Exception(\'Server Reflection timed out after 5 seconds. Check port and TLS connection settings.\');')

with open('lib/services/grpc_service.dart', 'w') as f:
    f.write(text)
