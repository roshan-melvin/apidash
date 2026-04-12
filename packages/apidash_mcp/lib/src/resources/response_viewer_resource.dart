import 'package:mcp_dart/mcp_dart.dart';
import '../ui/panels/response_viewer_panel.dart';

void registerResponseViewerResource(McpServer server) {
  server.registerResource(
    'response-viewer-ui',
    'ui://apidash-mcp/response-viewer',
    (description: 'Displays the last HTTP response received in APIDash.', mimeType: 'text/html;profile=mcp-app'),
    (Uri uri, RequestHandlerExtra extra) async {
      final html = buildResponseViewerPanel();
      return ReadResourceResult(
        contents: [
          TextResourceContents(uri: uri.toString(), mimeType: 'text/html;profile=mcp-app', text: html),
        ],
      );
    },
    title: 'Response Viewer',
  );
}
