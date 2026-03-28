with open('lib/services/grpc_reflection_service.dart', 'r') as f:
    text = f.read()

# Make sure we add a timeout directly on the stream of server reflection so it fails gracefully.
old_list = '''    final responseStream = client.serverReflectionInfo(controller.stream);
    try {
      await for (final resp in responseStream) {'''

new_list = '''    final responseStream = client.serverReflectionInfo(controller.stream);
    try {
      await for (final resp in responseStream.timeout(const Duration(seconds: 15), onTimeout: (sink) {
        sink.addError(GrpcReflectionException('Server Reflection timed out. Check TLS/SSL settings and port.'));
      })) {'''

text = text.replace(old_list, new_list)

old_fetch = '''    final responseStream = client.serverReflectionInfo(controller.stream);
    
    try {
      await for (final resp in responseStream) {'''

new_fetch = '''    final responseStream = client.serverReflectionInfo(controller.stream);
    
    try {
      await for (final resp in responseStream.timeout(const Duration(seconds: 15), onTimeout: (sink) {
        sink.addError(GrpcReflectionException('Server Reflection timed out. Check TLS/SSL settings and port.'));
      })) {'''

text = text.replace(old_fetch, new_fetch)

old_resolve = '''    final responseStream = client.serverReflectionInfo(controller.stream);

    try {
      await for (final resp in responseStream) {'''

new_resolve = '''    final responseStream = client.serverReflectionInfo(controller.stream);

    try {
      await for (final resp in responseStream.timeout(const Duration(seconds: 15), onTimeout: (sink) {
        sink.addError(GrpcReflectionException('Server Reflection timed out. Check TLS/SSL settings and port.'));
      })) {'''

text = text.replace(old_resolve, new_resolve)

with open('lib/services/grpc_reflection_service.dart', 'w') as f:
    f.write(text)
