import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';

void registerGraphqlExecuteQuery(McpServer server) {
  server.registerTool(
    'graphql-execute-query',
    description: 'Execute a GraphQL query or mutation against an endpoint. '
        'Returns status, data, hasErrors, and duration in ms.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': {
        'url': {'type': 'string', 'description': 'GraphQL endpoint URL'},
        'query': {'type': 'string', 'description': 'GraphQL query or mutation'},
        'variables': {
          'type': 'object',
          'description': 'Optional variables map',
          'additionalProperties': <String, dynamic>{},
        },
        'headers': {
          'type': 'object',
          'additionalProperties': {'type': 'string'},
        },
        'operationName': {'type': 'string'},
      },
      'required': ['url', 'query'],
    }),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final ctx = GraphQLRequestContext(
        url: args['url'] as String,
        query: args['query'] as String,
        variables: (args['variables'] as Map?)?.cast<String, dynamic>(),
        operationName: args['operationName'] as String?,
        headers: (args['headers'] as Map?)?.cast<String, String>(),
      );

      final result = await executeGraphQLRequest(ctx);
      final d = result.data;
      final hasErrors = d.errors != null && d.errors!.isNotEmpty;
      final emoji = (result.success && !hasErrors) ? '✅' : '❌';

      final structured = <String, dynamic>{
        'status': d.status,
        'statusText': d.statusText,
        'data': d.data,
        'errors': d.errors,
        'hasErrors': hasErrors,
        'duration': d.duration,
        'url': d.url,
      };

      return CallToolResult(
        content: [
          TextContent(
            text: '$emoji **${d.status} ${d.statusText}** · ${d.duration}ms'
                '${hasErrors ? '\n\n⚠️ GraphQL errors:\n```json\n${const JsonEncoder.withIndent('  ').convert(d.errors)}\n```' : ''}'
                '\n\n```json\n${const JsonEncoder.withIndent('  ').convert(d.data)}\n```',
          ),
        ],
        structuredContent: structured,
        isError: !result.success,
      );
    },
  );
}
