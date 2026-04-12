import 'package:mcp_dart/mcp_dart.dart';

void registerGraphqlExplorer(McpServer server) {
  server.registerTool(
    'graphql-explorer',
    description: 'Stub for graphql-explorer',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{'type': 'object', 'properties': <String, dynamic>{}}),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      return CallToolResult.fromContent([TextContent(text: 'Stub graphql-explorer executed')]);
    }
  );
}
