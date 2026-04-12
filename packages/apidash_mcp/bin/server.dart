import 'dart:io';
import 'dart:convert';
import 'package:apidash_mcp/apidash_mcp.dart';
import 'package:apidash_mcp/src/server/sse_server.dart';
import 'package:apidash_mcp/src/oauth/routes.dart';
import 'package:apidash_mcp/src/oauth/store.dart';
import 'package:apidash_mcp/src/routes/health.dart';
import 'package:apidash_mcp/src/routes/well_known.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';

Future<bool> _checkAuth(HttpRequest request) async {
  final oauthMode = Platform.environment['APIDASH_MCP_AUTH'] == 'true';
  final staticToken = Platform.environment['APIDASH_MCP_TOKEN'];

  if (!oauthMode && (staticToken == null || staticToken.isEmpty)) return true;

  final authHeader = request.headers.value('authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    request.response
      ..statusCode = 401
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': 'invalid_token',
          'error_description': 'Authorization: Bearer <token> required'}));
    await request.response.close();
    return false;
  }

  final token = authHeader.substring(7).trim();
  if (validateAccessToken(token) != null) return true;
  if (staticToken != null && token == staticToken) return true;

  request.response
    ..statusCode = 401
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({'error': 'invalid_token',
        'error_description': 'Token invalid or expired'}));
  await request.response.close();
  return false;
}

void main(List<String> args) async {
  final server = createMcpServer();

  if (args.contains('--stdio')) {
    final transport = StdioServerTransport();
    await server.connect(transport);
    return;
  }

  final port = int.tryParse(Platform.environment['PORT'] ?? '8000') ?? 8000;
  final httpServer = await HttpServer.bind('localhost', port);
  stderr.writeln('Server listening on port ${httpServer.port}');

  final oauthMode = Platform.environment['APIDASH_MCP_AUTH'] == 'true';
  final staticToken = Platform.environment['APIDASH_MCP_TOKEN'];
  if (oauthMode) {
    stderr.writeln('Auth Mode: OAuth 2.1');
    stderr.writeln('  POST http://localhost:$port/register');
    stderr.writeln('  GET  http://localhost:$port/authorize');
    stderr.writeln('  POST http://localhost:$port/token');
    stderr.writeln('  GET  http://localhost:$port/.well-known/oauth-authorization-server');
  } else if (staticToken != null && staticToken.isNotEmpty) {
    stderr.writeln('Auth Mode: Static Token');
  } else {
    stderr.writeln('Auth Mode: Open (No Auth)');
  }

  bool isSse = args.contains('--sse');
  final transportSse = isSse ? await setupSseServer(server) : null;
  final transportHttp = !isSse ? await setupRequestRouter(server) : null;

  final publicRouter = Router()
    ..mount('/', oauthRouter.call)
    ..mount('/', wellKnownRouter.call)
    ..mount('/', healthRouter.call);
  
  final publicPipeline = const Pipeline().addHandler(publicRouter.call);

  await for (final request in httpServer) {
    final path = request.uri.path;

    if (path == '/health' ||
        path == '/.well-known/oauth-authorization-server' ||
        path == '/.well-known/oauth-protected-resource' ||
        path == '/.well-known/mcp' ||
        path == '/register' ||
        path == '/authorize' ||
        path == '/authorize/confirm' ||
        path == '/token' ||
        path == '/token/revoke') {
      shelf_io.handleRequest(request, publicPipeline);
      continue;
    }

    if (path.startsWith('/mcp') || path.startsWith('/sse')) {
      if (!await _checkAuth(request)) continue;

      if (isSse) {
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization, Mcp-Session-Id');

        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          continue;
        }
        
        transportSse!.handleRequest(request).catchError((e) {
          try {
            request.response.statusCode = HttpStatus.internalServerError;
            request.response.close();
          } catch (_) {}
        });
      } else {
        transportHttp!.handleRequest(request).catchError((e) {
          // ignore
        });
      }
    }
  }
}
