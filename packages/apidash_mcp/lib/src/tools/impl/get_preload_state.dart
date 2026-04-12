import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';

/// Called by UI panels on init to discover what request (if any) was
/// requested to be pre-selected.  Consumes the pending state so it
/// is only used once.
void registerGetPreloadState(McpServer server) {
  server.registerTool(
    'get-preload-state',
    description: 'Internal: returns any pending preload request for a UI panel and clears it.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'panel': <String, dynamic>{'type': 'string'},
      },
    }),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final panel = args['panel'] as String? ?? '';
      Map<String, dynamic>? preload;

      if (panel == 'code-generator') {
        final preloadId = WorkspaceState().pendingCodegenPreloadId;
        if (preloadId != null) {
          preload = {'id': preloadId};
          WorkspaceState().pendingCodegenPreloadId = null;
        }
      } else if (panel == 'request-builder') {
        final pending = WorkspaceState().pendingBuilderPreload;
        if (pending != null) {
          preload = pending;
          WorkspaceState().pendingBuilderPreload = null;
        }
      }

      return CallToolResult(
        content: [TextContent(text: preload != null ? 'Preload: ${preload['name']}' : 'No preload')],
        structuredContent: <String, dynamic>{
          'preload': preload,
        },
      );
    },
  );
}
