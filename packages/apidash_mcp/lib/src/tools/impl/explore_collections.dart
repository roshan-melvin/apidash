import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../tool_ui_helper.dart';

void registerExploreCollections(McpServer server) {
  server.registerTool(
    'explore-collections',
    description: 'Open the Collections Explorer panel listing all saved API requests.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{},
    }),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final count = WorkspaceState().requests.length;
      return uiToolResult(
        resourceUri: kUriCollectionsExplorer,
        confirmationText: '✓ Collections Explorer opened — $count request(s) found.',
      );
    },
  );
}
