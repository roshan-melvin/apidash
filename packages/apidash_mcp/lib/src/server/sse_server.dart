import 'package:mcp_dart/mcp_dart.dart';

Future<SseServerManager> setupSseServer(McpServer server) async {
  return SseServerManager(
    server,
    ssePath: '/sse',
    messagePath: '/messages',
  );
}
