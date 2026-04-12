import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../ui/panels/env_manager_panel.dart';

void registerEnvManagerResource(McpServer server) {
  server.registerResource(
    'env-manager-ui',
    'ui://apidash-mcp/env-manager',
    (description: 'Tool to manage workspace environment variables securely.', mimeType: 'text/html;profile=mcp-app'),
    (Uri uri, RequestHandlerExtra extra) async {
      // Provide the workspace environments block as initial data
      final envList = WorkspaceState().environments;
      final environments = { 'global': envList.isNotEmpty ? envList.first : {} };
      
      final html = buildEnvManagerPanel(environments);
      return ReadResourceResult(
        contents: [
          TextResourceContents(uri: uri.toString(), mimeType: 'text/html;profile=mcp-app', text: html),
        ],
      );
    },
    title: 'Environment Manager',
  );
}
