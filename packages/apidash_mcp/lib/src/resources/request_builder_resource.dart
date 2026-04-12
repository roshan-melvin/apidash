import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../ui/panels/request_builder_panel.dart';

void registerRequestBuilderResource(McpServer server) {
  server.registerResource(
    'request-builder-ui',
    'ui://apidash-mcp/request-builder',
    (description: 'Interactive HTTP request builder with method selector, URL, params, headers, body, auth, and real-time response view.', mimeType: 'text/html;profile=mcp-app'),
    (Uri uri, RequestHandlerExtra extra) async {
      var html = buildRequestBuilderPanel();

      // Inject pending preload directly into HTML (works when VS Code re-fetches resource)
      final pending = WorkspaceState().pendingBuilderPreload;
      if (pending != null) {
        final script = '<script>window.__PRELOAD_REQUEST__ = ${jsonEncode(pending)};</script>';
        html = html.replaceFirst('</head>', '$script\n</head>');
        WorkspaceState().pendingBuilderPreload = null; // consume
      }

      return ReadResourceResult(
        contents: [
          TextResourceContents(uri: uri.toString(), mimeType: 'text/html;profile=mcp-app', text: html),
        ],
      );
    },
    title: 'Request Builder',
  );
}
