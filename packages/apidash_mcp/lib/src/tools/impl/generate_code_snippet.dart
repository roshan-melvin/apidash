import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../tool_ui_helper.dart';

void registerGenerateCodeSnippet(McpServer server) {
  server.registerTool(
    'generate-code-snippet',
    description: 'Generate a code snippet for an HTTP request in a specific language. '
        'Supported: ${supportedGenerators.join(", ")}',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'generator': <String, dynamic>{'type': 'string', 'enum': supportedGenerators},
        'method': <String, dynamic>{'type': 'string'},
        'url': <String, dynamic>{'type': 'string'},
        'headers': <String, dynamic>{
          'type': 'object',
          'additionalProperties': <String, dynamic>{'type': 'string'},
        },
        'body': <String, dynamic>{'type': 'string'},
      },
      'required': ['generator', 'method', 'url'],
    }),
    meta: {
      'ui': {
        'resourceUri': kUriCodeGenerator,
        'visibility': ['model', 'app'],
      },
    },
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final gen = args['generator'] as String;
      final method = args['method'] as String;
      final url = args['url'] as String;
      return uiToolResult(
        resourceUri: kUriCodeGenerator,
        confirmationText: '✓ Code Generator opened — $gen snippet for $method $url.',
      );
    },
  );
}
