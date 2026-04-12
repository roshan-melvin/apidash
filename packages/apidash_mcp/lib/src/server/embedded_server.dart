import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'mcp_server.dart';
import 'request_router.dart';
import '../ui/html_builders.dart';
import '../ui/panels/request_builder_panel.dart';
import '../ui/panels/code_generator_panel.dart';
import '../resources/code_generator_resource.dart';
import '../tools/tool_ui_helper.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import 'sse_server.dart';
import '../oauth/store.dart';
import '../oauth/routes.dart';
import '../routes/health.dart';
import '../routes/well_known.dart';

/// Hosts the MCP server **inside** the Flutter app process so that
/// [WorkspaceState] (a Dart singleton) is shared between the Flutter
/// Riverpod providers and the MCP tool callbacks without any IPC.
///
/// Usage in main.dart:
/// ```dart
/// if (kIsDesktop) await EmbeddedMcpServer.start();
/// ```
class EmbeddedMcpServer {
  static HttpServer? _httpServer;
  static bool _running = false;

  static bool get isRunning => _running;

  /// HTML pages served at GET /ui/<panel-name>
  /// When VS Code renders the EmbeddedResource chip or when resources/read
  /// is called, having an HTTP URL lets the webview load the page properly.
  static final _uiRoutes = <String, String Function()>{
    '/ui/request-builder': () {
      // Serve the full interactive panel, with any pending preload injected
      var html = buildRequestBuilderPanel();
      final pending = WorkspaceState().pendingBuilderPreload;
      if (pending != null) {
        final script =
            '<script>window.__PRELOAD_REQUEST__ = ${jsonEncode(pending)};</script>';
        html = html.replaceFirst('</head>', '$script\n</head>');
        WorkspaceState().pendingBuilderPreload = null;
      }
      return html;
    },
    '/ui/response-viewer':      buildResponseViewerHtml,
    '/ui/collections-explorer': buildCollectionsExplorerHtml,
    '/ui/graphql-explorer':     buildGraphqlExplorerHtml,
    '/ui/code-generator': () {
      final wsRequests = WorkspaceState().requests;
      final wsIds = wsRequests.map((r) => r['id'] as String? ?? '').toSet();
      final allRequests = [
        ...wsRequests,
        ...builtinTemplates.where((t) => !wsIds.contains(t['id'] as String)),
      ];
      
      var html = buildCodeGeneratorPanel(supportedGenerators);

      final injectionScript = '<script>window.__INITIAL_CONTEXT__ = ${jsonEncode(allRequests)};</script>';
      html = html.replaceFirst('</head>', '$injectionScript\n</head>');

      final preloadId = WorkspaceState().pendingCodegenPreloadId;
      if (preloadId != null) {
        final preloadScript = '<script>window.__PRELOAD_REQUEST_ID__ = ${jsonEncode(preloadId)};</script>';
        html = html.replaceFirst('</head>', '$preloadScript\n</head>');
        WorkspaceState().pendingCodegenPreloadId = null;
      }
      return html;
    },
    '/ui/env-manager':          buildEnvManagerHtml,
    '/ui/code-viewer':          buildCodeViewerHtml,
  };

  static Future<bool> _checkAuth(HttpRequest request) async {
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
    // Use validateAccessToken from oauth store
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

  /// Start the embedded MCP SSE server, trying [port] first then [port]+1..+9.
  /// Safe to call multiple times — subsequent calls are no-ops.
  static Future<void> start({int port = 8000, bool useSse = false}) async {
    if (_running) return;

    final server = createMcpServer();
    
    dynamic transport;
    if (useSse) {
      transport = await setupSseServer(server);
    } else {
      transport = await setupRequestRouter(server);
    }

    // Try preferred port, then fall back up to +9 to avoid conflicts
    for (var p = port; p < port + 10; p++) {
      try {
        _httpServer = await HttpServer.bind('localhost', p);
        break;
      } on SocketException {
        if (p == port + 9) {
          stderr.writeln(
            '[EmbeddedMcpServer] No free port in range $port–${port + 9}. '
            'Kill the other server and hot-restart.',
          );
          return;
        }
      }
    }

    _running = true;
    final boundPort = _httpServer!.port;
    
    final publicRouter = Router()
      ..mount('/', oauthRouter.call)
      ..mount('/', wellKnownRouter.call)
      ..mount('/', healthRouter.call);
    
    final publicPipeline = const Pipeline().addHandler(publicRouter.call);

    _httpServer!.listen(
      (request) async {
        final path = request.uri.path;

        // 1. /ui/* static HTML routes (no auth)
        final uiBuilder = _uiRoutes[path];
        if (uiBuilder != null && request.method == 'GET') {
          final html = uiBuilder();
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write(html);
          request.response.close();
          return;
        }
        
        // 2. Public OAuth + health routes (no auth)
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
          return;
        }

        // 3. MCP unified HTTP/SSE routes
        if (path.startsWith('/mcp') || path.startsWith('/sse')) {
          if (!await _checkAuth(request)) return;

          if (useSse) {
            request.response.headers.add('Access-Control-Allow-Origin', '*');
            request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
            request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization, Mcp-Session-Id');

            if (request.method == 'OPTIONS') {
              request.response.statusCode = HttpStatus.ok;
              request.response.close();
              return;
            }
            transport.handleRequest(request).catchError((e) {
              stderr.writeln('[EmbeddedMcpServer] request error: $e');
              try {
                request.response.statusCode = HttpStatus.internalServerError;
                request.response.close();
              } catch (_) {}
            });
          } else {
            transport.handleRequest(request).catchError((e) {
              stderr.writeln('[EmbeddedMcpServer] request error: $e');
            });
          }
        }
      },
      onError: (e) => stderr.writeln('[EmbeddedMcpServer] server error: $e'),
    );

    if (useSse) {
      stderr.writeln(
        '[EmbeddedMcpServer] ✓ APIDash MCP running → '
        'http://localhost:$boundPort/sse\n'
        '[EmbeddedMcpServer] UI panels → http://localhost:$boundPort/ui/request-builder',
      );
    } else {
      stderr.writeln(
        '[EmbeddedMcpServer] ✓ APIDash MCP running → '
        'http://localhost:$boundPort/mcp\n'
        '[EmbeddedMcpServer] UI panels → http://localhost:$boundPort/ui/request-builder\n'
        '[EmbeddedMcpServer] Update mcp.json if port ≠ $port: '
        '"url": "http://localhost:$boundPort/mcp"',
      );
    }
  }

  /// Gracefully shut down the HTTP server (called on app exit if needed).
  static Future<void> stop() async {
    await _httpServer?.close(force: true);
    _httpServer = null;
    _running = false;
  }
}
