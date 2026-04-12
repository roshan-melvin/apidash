import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../tool_ui_helper.dart';

void registerCodegenUi(McpServer server) {
  server.registerTool(
    'codegen-ui',
    description: 'Open the Code Generator panel. Optionally pass a preloadId to pre-select a specific saved request.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'method': <String, dynamic>{'type': 'string'},
        'url': <String, dynamic>{'type': 'string'},
        'preloadId': <String, dynamic>{'type': 'string', 'description': 'ID of the saved request to pre-select'},
        'request': <String, dynamic>{
          'type': 'object',
          'description': 'Alternatively, pass the full request object here',
          'properties': <String, dynamic>{
            'id': <String, dynamic>{'type': 'string'},
            'method': <String, dynamic>{'type': 'string'},
            'url': <String, dynamic>{'type': 'string'},
          },
        },
      },
    }),
    meta: {
      'ui': {
        'resourceUri': kUriCodeGenerator,
        'visibility': ['model', 'app'],
      },
    },
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final nested = args['request'] as Map<String, dynamic>?;
      final src = nested ?? args;

      final method = src['method'] as String? ?? 'GET';
      final url = src['url'] as String? ?? '';
      final preloadId = src['preloadId'] as String? ?? src['id'] as String?;
      // Store preload ID so the resource can inject it on next fetch
      if (preloadId != null && preloadId.isNotEmpty) {
        WorkspaceState().pendingCodegenPreloadId = preloadId;
      }
      return uiToolResult(
        resourceUri: kUriCodeGenerator,
        confirmationText:
            '✓ Code Generator opened${preloadId != null ? ' — pre-selected: $preloadId' : ''} — $method ${url.isEmpty ? '(no URL set)' : url} '
            'in ${supportedGenerators.length} languages.',
      );
    },
  );
}
