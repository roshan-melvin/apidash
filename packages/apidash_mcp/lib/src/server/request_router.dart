import 'package:mcp_dart/mcp_dart.dart';

SseServerManager setupRequestRouter(McpServer server) {
  return SseServerManager(
    server,
    ssePath: '/mcp/sse',
    messagePath: '/mcp/messages',
  );
}
