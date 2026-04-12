import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';

void registerUpdateEnvironmentVariables(McpServer server) {
  server.registerTool(
    'update-environment-variables',
    description:
        'Search or list environment variable keys/values from the live '
        'APIDash workspace. Pass an optional search term to filter. '
        'Requires APIDash to be running with the embedded MCP server.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'search': <String, dynamic>{
          'type': 'string',
          'description': 'Optional filter term applied to key or value',
        },
      },
    }),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final envs = WorkspaceState().environments;
      if (envs.isEmpty) {
        return CallToolResult.fromContent([
          TextContent(text: 'No environment variables found in APIDash.'),
        ]);
      }
      final search = args['search'] as String?;
      if (search == null || search.isEmpty) {
        return CallToolResult.fromContent([
          TextContent(
            text: const JsonEncoder.withIndent('  ').convert(envs),
          ),
        ]);
      }
      // Flatten and filter by search term
      final filtered = <Map<String, dynamic>>[];
      for (final env in envs) {
        final vars = env['variables'] as List? ?? [];
        final matched = vars
            .cast<Map>()
            .where(
              (v) =>
                  (v['key'] as String? ?? '').contains(search) ||
                  (v['value'] as String? ?? '').contains(search),
            )
            .toList();
        if (matched.isNotEmpty) {
          filtered.add({
            'environment': env['name'],
            'matches': matched,
          });
        }
      }
      if (filtered.isEmpty) {
        return CallToolResult.fromContent([
          TextContent(text: 'No matches for "$search".'),
        ]);
      }
      return CallToolResult.fromContent([
        TextContent(
          text: const JsonEncoder.withIndent('  ').convert(filtered),
        ),
      ]);
    },
  );
}
