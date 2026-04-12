import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../tool_ui_helper.dart';

void registerManageEnvironment(McpServer server) {
  server.registerTool(
    'manage-environment',
    description: 'Open the Environment Manager panel showing all APIDash environments and variables.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{},
    }),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final count = WorkspaceState().environments.length;
      return uiToolResult(
        resourceUri: kUriEnvManager,
        confirmationText: '✓ Environment Manager opened — $count environment(s) loaded.',
      );
    },
  );
}
