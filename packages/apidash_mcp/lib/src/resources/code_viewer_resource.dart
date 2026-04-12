import 'package:mcp_dart/mcp_dart.dart';
import '../ui/panels/code_viewer_panel.dart';

void registerCodeViewerResource(McpServer server) {
  server.registerResource(
    'code-viewer-ui',
    'ui://apidash-mcp/code-viewer',
    (description: 'View APIDash MCP tool references and capabilities.', mimeType: 'text/html;profile=mcp-app'),
    (Uri uri, RequestHandlerExtra extra) async {
      final html = buildCodeViewerPanel();
      return ReadResourceResult(
        contents: [
          TextResourceContents(uri: uri.toString(), mimeType: 'text/html;profile=mcp-app', text: html),
        ],
      );
    },
    title: 'Tool Reference',
  );
}
