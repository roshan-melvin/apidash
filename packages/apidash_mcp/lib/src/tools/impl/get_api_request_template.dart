import 'package:mcp_dart/mcp_dart.dart';
import '../tool_ui_helper.dart';

void registerGetApiRequestTemplate(McpServer server) {
  server.registerTool(
    'get-api-request-template',
    description: 'Open the Request Builder panel with a blank template for the given HTTP method.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'method': <String, dynamic>{
          'type': 'string',
          'enum': ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD'],
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
      final method = (args['method'] as String? ?? 'GET').toUpperCase();
      return uiToolResult(
        resourceUri: kUriRequestBuilder,
        confirmationText: '✓ Request Builder opened with blank $method template.',
      );
    },
  );
}
