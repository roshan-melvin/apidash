import 'dart:io';

void main() {
  final dir = Directory('lib/src/tools/impl');
  final files = dir.listSync().whereType<File>().toList();
  
  for (final file in files) {
    if (file.path.endsWith('ai_llm_request.dart') || file.path.endsWith('http_send_request.dart')) continue;
    
    final nameStr = file.uri.pathSegments.last.replaceAll('.dart', '');
    final camelName = nameStr.split('_').map((s) => s[0].toUpperCase() + s.substring(1)).join('');
    final mcpName = nameStr.replaceAll('_', '-');
    
    final content = '''import 'package:mcp_dart/mcp_dart.dart';

void register$camelName(McpServer server) {
  server.registerTool(
    '$mcpName',
    description: 'Stub for $mcpName',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{'type': 'object', 'properties': <String, dynamic>{}}),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      return CallToolResult.fromContent([TextContent(text: 'Stub $mcpName executed')]);
    }
  );
}
''';
    file.writeAsStringSync(content);
  }
}
