import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../tool_ui_helper.dart';

void registerRequestBuilder(McpServer server) {
  server.registerTool(
    'request-builder',
    description: 'Open the APIDash request builder panel showing all workspace requests.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{},
    }),
    meta: {
      'ui': {
        'resourceUri': kUriRequestBuilder,
        'visibility': ['model', 'app'],
      },
    },
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final count = WorkspaceState().requests.length;
      return uiToolResult(

        resourceUri: kUriRequestBuilder,
        confirmationText: '✓ Request Builder opened — $count request(s) in workspace.',
      );
    },
  );
}
