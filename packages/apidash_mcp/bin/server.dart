import 'dart:io';
import 'package:apidash_mcp/apidash_mcp.dart';
import 'package:mcp_dart/mcp_dart.dart';

void main(List<String> args) async {
  final server = createMcpServer();

  if (args.contains('--stdio')) {
    final transport = StdioServerTransport();
    await server.connect(transport);
  } else {
    final manager = setupRequestRouter(server);
    final port = int.tryParse(Platform.environment['PORT'] ?? '8000') ?? 8000;
    
    final httpServer = await HttpServer.bind('localhost', port);
    print('Server listening on port ${httpServer.port}');
    
    await for (final request in httpServer) {
      // Add CORS middleware
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization');

      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        continue;
      }
      
      manager.handleRequest(request).catchError((e) {
        print('Error handling request: $e');
        try {
          request.response.statusCode = HttpStatus.internalServerError;
          request.response.close();
        } catch (_) {}
      });
    }
  }
}
