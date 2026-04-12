import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../tool_ui_helper.dart';

void registerGetLastResponse(McpServer server) {
  server.registerTool(
    'get-last-response',
    description: 'Open the Response Viewer panel with the last APIDash HTTP response.',
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
      final status = last?['responseStatus'];
      final name = last?['name']?.toString() ?? '';
      final msg = status != null
          ? 'Last response: $status${name.isNotEmpty ? ' — $name' : ''}'
          : 'No response yet';
      return uiToolResult(
        resourceUri: kUriResponseViewer,
        confirmationText: '✓ $msg',
      );
    },
  );
}
