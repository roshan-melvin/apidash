with open('lib/services/grpc_service.dart', 'r') as f:
    text = f.read()

old_disc = '''    Future<void> disconnect() async {
      if (_channel != null) {
        try {
          await _channel!.shutdown();
        } catch (e) {
          debugPrint("[gRPC] Error shutting down channel: $e");
        }
        _channel = null;
      }'''

new_disc = '''    Future<void> disconnect() async {
      if (_channel != null) {
        try {
          await _channel!.shutdown().timeout(const Duration(seconds: 2));
        } catch (e) {
          debugPrint("[gRPC] Error shutting down channel: $e");
        }
        _channel = null;
      }'''

text = text.replace(old_disc, new_disc)

with open('lib/services/grpc_service.dart', 'w') as f:
    f.write(text)
