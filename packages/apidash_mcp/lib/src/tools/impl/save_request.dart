import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';

void registerSaveRequest(McpServer server) {
  server.registerTool(
    'save-request',
    description:
        'Queue a new API request to be added to the APIDash workspace. '
        'The Flutter app picks it up on the next sync cycle. '
        'Requires APIDash to be running with the embedded MCP server.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'name': <String, dynamic>{'type': 'string', 'description': 'Display name'},
        'method': <String, dynamic>{
          'type': 'string',
          'enum': ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD'],
        },
        'url': <String, dynamic>{'type': 'string'},
        'headers': <String, dynamic>{
          'type': 'object',
          'additionalProperties': <String, dynamic>{'type': 'string'},
        },
        'body': <String, dynamic>{'type': 'string'},
      },
      'required': ['method', 'url'],
    }),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final req = <String, dynamic>{
        'name': args['name'] ?? '',
        'method': (args['method'] as String).toLowerCase(),
        'url': args['url'],
        'headers': args['headers'] ?? <String, dynamic>{},
        'body': args['body'],
        'source': 'mcp',
        'timestamp': DateTime.now().toIso8601String(),
      };
      WorkspaceState().queueRequest(req);
      final label = (args['name'] as String? ?? '').isNotEmpty
          ? args['name'] as String
          : args['url'] as String;
      return CallToolResult.fromContent([
        TextContent(
          text: 'Request "$label" queued. '
              'It will appear in APIDash on the next workspace sync.',
        ),
      ]);
    },
  );
}
