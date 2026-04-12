import 'package:mcp_dart/mcp_dart.dart';
import '../ui/panels/graphql_explorer_panel.dart';

void registerGraphqlExplorerResource(McpServer server) {
  server.registerResource(
    'graphql-explorer-ui',
    'ui://apidash-mcp/graphql-explorer',
    (description: 'GraphQL explorer panel with usage guide and example queries.', mimeType: 'text/html;profile=mcp-app'),
    (Uri uri, RequestHandlerExtra extra) async {
      final html = buildGraphqlExplorerPanel();
      return ReadResourceResult(
        contents: [
          TextResourceContents(uri: uri.toString(), mimeType: 'text/html;profile=mcp-app', text: html),
        ],
      );
    },
    title: 'GraphQL Explorer',
  );
}
