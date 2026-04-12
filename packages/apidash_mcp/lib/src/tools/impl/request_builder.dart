import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../tool_ui_helper.dart';

void registerRequestBuilder(McpServer server) {
  server.registerTool(
    'request-builder',
    description: 'Open the APIDash request builder panel. '
        'IMPORTANT: If the user has a request in context (from "Add to Chat" or a saved collection), '
        'you MUST pass its details as arguments to pre-fill the form. '
        'Pass method, url, name, body from the request data in the conversation context.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        // Flat fields (preferred)
        'method': <String, dynamic>{
          'type': 'string',
          'description': 'HTTP method (GET, POST, PUT, PATCH, DELETE)',
          'enum': ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD'],
        },
        'url': <String, dynamic>{
          'type': 'string',
          'description': 'Request URL to pre-fill',
        },
        'name': <String, dynamic>{
          'type': 'string',
          'description': 'Human-readable name of the request',
        },
        'body': <String, dynamic>{
          'type': 'string',
          'description': 'Request body (JSON string or text)',
        },
        'id': <String, dynamic>{
          'type': 'string',
          'description': 'Request ID if available',
        },
        // Nested wrapper — accepted when model passes the whole request object
        'request': <String, dynamic>{
          'type': 'object',
          'description': 'Alternatively, pass the full request object here',
          'properties': <String, dynamic>{
            'method': <String, dynamic>{'type': 'string'},
            'url': <String, dynamic>{'type': 'string'},
            'name': <String, dynamic>{'type': 'string'},
            'body': <String, dynamic>{'type': 'string'},
            'id': <String, dynamic>{'type': 'string'},
            'description': <String, dynamic>{'type': 'string'},
          },
        },
      },
    }),
    meta: {
      'ui': {
        'resourceUri': kUriRequestBuilder,
        'visibility': ['model', 'app'],
      },
    },
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final count = WorkspaceState().requests.length;

      // Support both flat args and a nested 'request' wrapper object.
      // The model sometimes passes { "request": { "method": ..., "url": ... } }
      // instead of flat top-level fields.
      final nested = args['request'] as Map<String, dynamic>?;
      final src = nested ?? args;

      final method = src['method'] as String?;
      final url = src['url'] as String?;
      final name = src['name'] as String?;
      final body = src['body'] as String?;
      final id = src['id'] as String?;

      if (url != null && url.isNotEmpty) {
        WorkspaceState().pendingBuilderPreload = <String, dynamic>{
          if (id != null) 'id': id,
          if (name != null) 'name': name,
          if (method != null) 'method': method,
          'url': url,
          if (body != null) 'body': body,
        };
      }

      final label = name ?? url ?? '';
      return uiToolResult(
        resourceUri: kUriRequestBuilder,
        confirmationText: label.isNotEmpty
            ? '✓ Request Builder opened — pre-loading: $label'
            : '✓ Request Builder opened — $count request(s) in workspace.',
      );
    },
  );
}
