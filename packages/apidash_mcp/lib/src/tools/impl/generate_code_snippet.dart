import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';

void registerGenerateCodeSnippet(McpServer server) {
  server.registerTool(
    'generate-code-snippet',
    description: 'Generate a ready-to-run code snippet for an HTTP request in a specific language. '
        'Supported generators: ${supportedGenerators.join(", ")}.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'generator': <String, dynamic>{'type': 'string', 'enum': supportedGenerators},
        'method': <String, dynamic>{'type': 'string', 'description': 'HTTP method (GET, POST, etc.)'},
        'url': <String, dynamic>{'type': 'string', 'description': 'Full request URL'},
        'headers': <String, dynamic>{
          'type': 'object',
          'additionalProperties': <String, dynamic>{'type': 'string'},
        },
        'body': <String, dynamic>{'type': 'string', 'description': 'Request body string'},
      },
      'required': ['generator', 'method', 'url'],
    }),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final gen = args['generator'] as String;
      final method = (args['method'] as String).toUpperCase();
      final url = args['url'] as String;
      final headers = (args['headers'] as Map?)?.cast<String, String>();
      final body = args['body'] as String?;

      final input = CodeGenInput(
        method: method,
        url: url,
        headers: headers,
        body: body,
      );

      final code = generateCode(gen, input);
      final lang = _lang(gen);

      return CallToolResult(
        content: [
          TextContent(
            text: '**$gen** snippet for `$method $url`\n\n```$lang\n$code\n```',
          ),
        ],
        structuredContent: <String, dynamic>{
          'generator': gen,
          'language': lang,
          'code': code,
          'method': method,
          'url': url,
        },
      );
    },
  );
}

String _lang(String gen) {
  if (gen.startsWith('python')) return 'python';
  if (gen.startsWith('javascript') || gen.startsWith('nodejs')) return 'javascript';
  if (gen.startsWith('dart')) return 'dart';
  if (gen.startsWith('go')) return 'go';
  if (gen.startsWith('java') && !gen.startsWith('javascript')) return 'java';
  if (gen.startsWith('kotlin')) return 'kotlin';
  if (gen.startsWith('php')) return 'php';
  if (gen.startsWith('ruby')) return 'ruby';
  if (gen.startsWith('rust')) return 'rust';
  return 'bash';
}
