import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';

void registerHttpSendRequest(McpServer server) {
  server.registerTool(
    'http-send-request',
    description: 'Send an HTTP request via the internal protocol support',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': {
        'method': {
          'type': 'string',
          'enum': ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'get', 'post', 'put', 'patch', 'delete', 'head']
        },
        'url': {'type': 'string'},
        'headers': {
          'type': 'object',
          'additionalProperties': {'type': 'string'}
        },
        'body': {'type': 'string'}
      },
      'required': ['method', 'url']
    }),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final ctx = HttpRequestContext(
        method: args['method'] as String? ?? 'get',
        url: args['url'] as String? ?? '',
        headers: (args['headers'] as Map?)?.cast<String, String>(),
        body: args['body'] as String?,
      );
      final result = await executeHttpRequest(ctx);
      return CallToolResult.fromContent([TextContent(text: jsonEncode(result))]);
    },
  );
}
