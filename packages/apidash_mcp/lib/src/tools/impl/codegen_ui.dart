import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../tool_ui_helper.dart';

void registerCodegenUi(McpServer server) {
  server.registerTool(
    'codegen-ui',
    description: 'Open the Code Generator panel for all supported languages.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'method': <String, dynamic>{'type': 'string'},
        'url': <String, dynamic>{'type': 'string'},
      },
    }),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final method = args['method'] as String? ?? 'GET';
      final url = args['url'] as String? ?? '';
      return uiToolResult(
        resourceUri: kUriCodeGenerator,
        confirmationText:
            '✓ Code Generator opened — $method ${url.isEmpty ? '(no URL set)' : url} '
            'in ${supportedGenerators.length} languages.',
      );
    },
  );
}
