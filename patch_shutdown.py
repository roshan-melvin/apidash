with open('lib/services/grpc_service.dart', 'r') as f:
    text = f.read()

old_shutdown = '''      if (_channel != null) {
        try {
          await _channel!.shutdown();
        } catch (_) {}
        _channel = null;
      }'''

new_shutdown = '''      if (_channel != null) {
        try {
          // Do not await shutdown. It can hang indefinitely on broken TLS/HTTP2 connections!
          _channel!.shutdown();
        } catch (_) {}
        _channel = null;
      }'''

text = text.replace(old_shutdown, new_shutdown)

with open('lib/services/grpc_service.dart', 'w') as f:
    f.write(text)
