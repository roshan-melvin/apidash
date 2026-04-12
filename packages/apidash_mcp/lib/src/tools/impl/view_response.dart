import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../tool_ui_helper.dart';

void registerViewResponse(McpServer server) {
  server.registerTool(
    'view-response',
    description: 'Display the last APIDash HTTP response in a rich viewer panel.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{},
    }),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final last = WorkspaceState().lastResponse;
      final status = last?['responseStatus'];
      final msg = status != null ? 'Status $status' : 'No response yet';
      return uiToolResult(
        resourceUri: kUriResponseViewer,
        confirmationText: '✓ Response Viewer opened — $msg.',
      );
    },
  );
}
