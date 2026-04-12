import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';

void registerHttpSendRequest(McpServer server) {
  server.registerTool(
    'http-send-request',
    description: 'Execute a real HTTP request and return status, headers, body, and duration. '
        'Supported methods: GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': {
        'method': {
          'type': 'string',
          'enum': ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'],
        },
        'url': {'type': 'string', 'description': 'Full URL including https://'},
        'headers': {
          'type': 'object',
          'additionalProperties': {'type': 'string'},
        },
        'body': {'type': 'string', 'description': 'Request body string'},
      },
      'required': ['method', 'url'],
    }),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final ctx = HttpRequestContext(
        method: (args['method'] as String? ?? 'GET').toUpperCase(),
        url: args['url'] as String? ?? '',
        headers: (args['headers'] as Map?)?.cast<String, String>(),
        body: args['body'] as String?,
      );

      final result = await executeHttpRequest(ctx);
      // executor returns { success, data: { status, statusText, headers, body, duration, ... } }
      final data = result['data'] as Map<String, dynamic>? ?? {};
      final status = data['status'] as int? ?? 0;
      final statusText = data['statusText'] as String? ?? '';
      final body = data['body'] as String? ?? '';
      final headers = (data['headers'] as Map?)?.cast<String, String>() ?? {};
      final duration = data['duration'] as int? ?? 0;
      final success = result['success'] as bool? ?? false;

      // Store as last response for Response Viewer
      WorkspaceState().lastResponse = {
        'responseStatus': status,
        'statusText': statusText,
        'body': body,
        'headers': headers,
        'url': ctx.url,
        'method': ctx.method,
        'time': duration,
        'duration': duration,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // structuredContent lets the Request Builder iframe render the response
      final structured = <String, dynamic>{
        'status': status,
        'statusText': statusText,
        'body': body,
        'headers': headers,
        'url': ctx.url,
        'method': ctx.method,
        'duration': duration,
        'success': success,
      };

      final emoji = success ? '✅' : '❌';
      return CallToolResult(
        content: [
          TextContent(
            text: '$emoji **$status $statusText** · ${duration}ms\n\n'
                '```json\n${const JsonEncoder.withIndent('  ').convert(structured)}\n```',
          ),
        ],
        structuredContent: structured,
      );
    },
  );
}
