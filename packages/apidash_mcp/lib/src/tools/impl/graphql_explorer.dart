import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../tool_ui_helper.dart';

void registerGraphqlExplorer(McpServer server) {
  server.registerTool(
    'graphql-explorer',
    description: 'Open the interactive GraphQL Explorer panel pre-wired to the Countries public API. '
        'Provides a query editor, variables editor, and real-time result viewer.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'url': <String, dynamic>{
          'type': 'string',
          'description': 'GraphQL endpoint URL (default: https://countries.trevorblades.com/graphql)',
        },
        'query': <String, dynamic>{
          'type': 'string',
          'description': 'Optional pre-filled GraphQL query',
        },
      },
    }),
    meta: {
      'ui': {
        'resourceUri': kUriGraphqlExplorer,
        'visibility': ['model', 'app'],
      },
    },
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final url = args['url'] as String? ?? 'https://countries.trevorblades.com/graphql';
      return uiToolResult(
        resourceUri: kUriGraphqlExplorer,
        confirmationText: '✓ GraphQL Explorer opened — endpoint: $url',
      );
    },
  );
}
