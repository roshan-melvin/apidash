import 'package:mcp_dart/mcp_dart.dart';

void registerGraphqlExecuteQuery(McpServer server) {
  server.registerTool(
    'graphql-execute-query',
    description: 'Stub for graphql-execute-query',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{'type': 'object', 'properties': <String, dynamic>{}}),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      return CallToolResult.fromContent([TextContent(text: 'Stub graphql-execute-query executed')]);
    }
  );
}
