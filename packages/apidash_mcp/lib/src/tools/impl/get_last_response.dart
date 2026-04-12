import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../tool_ui_helper.dart';

void registerGetLastResponse(McpServer server) {
  server.registerTool(
    'get-last-response',
    description: 'Fetch the last HTTP response from the APIDash workspace and display it in the Response Viewer panel.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{},
    }),
    meta: {
      'ui': {
        'resourceUri': kUriResponseViewer,
        'visibility': ['model', 'app'],
      },
    },
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final last = WorkspaceState().lastResponse;
      final status = last?['responseStatus'] as int?;
      final msg = status != null ? 'Last response: $status' : 'No response yet — send a request first.';

      // Return structuredContent so the Response Viewer iframe can read it
      return CallToolResult(
        content: [TextContent(text: '✓ $msg')],
        structuredContent: <String, dynamic>{
          'lastResponse': last ?? {},
        },
        meta: {
          'ui': {
            'resourceUri': kUriResponseViewer,
            'visibility': ['model', 'app'],
          },
        },
      );
    },
  );
}
