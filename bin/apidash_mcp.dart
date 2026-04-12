import 'dart:io';
import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'package:apidash_mcp/apidash_mcp.dart';
import 'package:apidash_mcp/src/server/sse_server.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp/src/oauth/routes.dart';
import 'package:apidash_mcp/src/oauth/store.dart';
import 'package:apidash_mcp/src/routes/health.dart';
import 'package:apidash_mcp/src/routes/well_known.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';

final Map<String, String> _envOverrides = {};

void _loadDotEnv() {
  try {
    final envFile = File('.env');
    if (!envFile.existsSync()) return;
    for (final line in envFile.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final idx = trimmed.indexOf('=');
      if (idx == -1) continue;
      final key = trimmed.substring(0, idx).trim();
      final value = trimmed.substring(idx + 1).trim();
      if (key.isNotEmpty) {
        _envOverrides[key] = value;
      }
    }
  } catch (_) {}
}

String? _env(String key) => _envOverrides[key] ?? Platform.environment[key];

Future<bool> _checkAuth(HttpRequest request, {required bool oauthMode, required String? staticToken}) async {
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

const String kDataBox        = 'apidash-data';
const String kEnvironmentBox = 'apidash-environments';
const String kKeyDataBoxIds  = 'ids';
const String kKeyEnvBoxIds   = 'environmentIds';

String _resolvePath() {
  String defaultPath;
  String? prefsPath;

  if (Platform.isLinux) {
    defaultPath = '${Platform.environment['HOME']}/.local/share/apidash';
    final linuxPref = '${Platform.environment['HOME']}/.local/share/com.example.apidash/shared_preferences.json';
    if (File(linuxPref).existsSync()) prefsPath = linuxPref;
  } else if (Platform.isMacOS) {
    defaultPath = '${Platform.environment['HOME']}/Library/Application Support/apidash';
    // Mac usually stores in plist, harder to safely parse in pure dart without dependencies.
  } else if (Platform.isWindows) {
    defaultPath = '${Platform.environment['LOCALAPPDATA']}\\apidash';
  } else {
    throw UnsupportedError('Unsupported platform');
  }

  // Attempt to sync the path with the GUI's apidash-settings overriding if present
  if (prefsPath != null && File(prefsPath).existsSync()) {
    try {
      final content = File(prefsPath).readAsStringSync();
      final map = jsonDecode(content) as Map;
      final settingsRaw = map['flutter.apidash-settings'];
      if (settingsRaw is String) {
        final settings = jsonDecode(settingsRaw) as Map;
        final overridePath = settings['workspaceFolderPath'];
        if (overridePath is String && overridePath.isNotEmpty) {
          stderr.writeln('[apidash_mcp] Synced workspace path from GUI settings: $overridePath');
          return overridePath;
        }
      }
    } catch (_) {}
  }

  return defaultPath;
}

Future<void> _loadHiveIntoWorkspace() async {
  final dataBox = Hive.box(kDataBox);
  final envBox  = Hive.box(kEnvironmentBox);

  final rawIds = dataBox.get(kKeyDataBoxIds);
  final List<Map<String, dynamic>> requests = [];
  if (rawIds is List) {
    for (final id in rawIds) {
      final raw = dataBox.get(id.toString());
      if (raw == null) continue;
      try {
        final m = Map<String, dynamic>.from(raw as Map);
        requests.add({
          'id':             m['id'] ?? id,
          'name':           m['name'] ?? '',
          'method':         (m['httpRequestModel']?['method'] ?? 'GET').toString().toUpperCase(),
          'url':            m['httpRequestModel']?['url'] ?? '',
          'headers':        m['httpRequestModel']?['enabledHeadersMap'] ?? <String, String>{},
          'body':           m['httpRequestModel']?['body'],
          'responseStatus': m['responseStatus'],
          'responseBody':   m['httpResponseModel']?['body'],
          'isWorking':      m['isWorking'] ?? false,
        });
      } catch (_) {}
    }
  }

  final rawEnvIds = envBox.get(kKeyEnvBoxIds);
  final List<Map<String, dynamic>> envs = [];
  if (rawEnvIds is List) {
    for (final id in rawEnvIds) {
      final raw = envBox.get(id.toString());
      if (raw == null) continue;
      try {
        envs.add(Map<String, dynamic>.from(raw as Map));
      } catch (_) {}
    }
  }

  final store = WorkspaceState();
  store.updateRequests(requests);
  store.updateEnvironments(envs);
  stderr.writeln('[apidash_mcp] Loaded ${requests.length} request(s), ${envs.length} environment(s) from Hive.');
}

void main(List<String> args) async {
  _loadDotEnv();
  
  if (args.contains('--help') || args.contains('-h')) {
    stderr.writeln('''
APIDash Headless MCP Server

Usage: dart run bin/apidash_mcp.dart [options]

Options:
  --stdio        Use stdio transport
  --sse          Use legacy SSE transport  (endpoint: /sse)
  --http         Use Streamable HTTP transport (default, endpoint: /mcp)
  --port <n>     Port number (default: 8000, ignored for --stdio)
  --help         Show this help
''');
    exit(0);
  }

  final useStdio = args.contains('--stdio');
  final useSse   = args.contains('--sse');
  int port = 8000;
  final portIndex = args.indexOf('--port');
  if (portIndex != -1 && portIndex + 1 < args.length) {
    port = int.tryParse(args[portIndex + 1]) ?? 8000;
  }

  final hivePath = _resolvePath();
  try {
    Hive.init(hivePath);
    await Hive.openBox(kDataBox);
    await Hive.openBox(kEnvironmentBox);
  } catch (e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('lock') || msg.contains('hivelockerror')) {
      stderr.writeln('Error: APIDash GUI is currently running. Please close the main application to run the headless MCP server.');
      exit(1);
    }
    stderr.writeln('[apidash_mcp] Failed to open Hive at $hivePath: $e');
    exit(1);
  }

  await _loadHiveIntoWorkspace();

  final server = createMcpServer();

  if (useStdio) {
    stderr.writeln('[apidash_mcp] Starting stdio transport...');
    stderr.writeln('mcp.json config:\n{\n  "mcpServers": {\n    "apidash-mcp": {\n      "command": "dart",\n      "args": ["run", "bin/apidash_mcp.dart", "--stdio"]\n    }\n  }\n}');
    final transport = StdioServerTransport();
    await server.connect(transport);
    return;
  }

  final oauthMode = _env('APIDASH_MCP_AUTH') == 'true';
  final staticToken = _env('APIDASH_MCP_TOKEN');
  if (oauthMode) {
    stderr.writeln('[apidash_mcp] Auth Mode: OAuth 2.1');
    stderr.writeln('[apidash_mcp]   POST http://localhost:$port/register');
    stderr.writeln('[apidash_mcp]   GET  http://localhost:$port/authorize');
    stderr.writeln('[apidash_mcp]   POST http://localhost:$port/token');
    stderr.writeln('[apidash_mcp]   GET  http://localhost:$port/.well-known/oauth-authorization-server');
  } else if (staticToken != null && staticToken.isNotEmpty) {
    stderr.writeln('[apidash_mcp] Auth Mode: Static Token');
  } else {
    stderr.writeln('[apidash_mcp] Auth Mode: Open (No Auth)');
  }

  final publicRouter = Router()
    ..mount('/', oauthRouter.call)
    ..mount('/', wellKnownRouter.call)
    ..mount('/', healthRouter.call);
  
  final publicPipeline = const Pipeline().addHandler(publicRouter.call);

  if (useSse) {
    final sseManager = await setupSseServer(server);
    final httpServer = await HttpServer.bind('localhost', port);
    stderr.writeln('[apidash_mcp] SSE server → http://localhost:$port/sse');
    stderr.writeln('mcp.json config:\n{\n  "mcpServers": {\n    "apidash-mcp": {\n      "url": "http://localhost:$port/sse"\n    }\n  }\n}');
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
        if (!await _checkAuth(request, oauthMode: oauthMode, staticToken: staticToken)) continue;

        request.response.headers
          ..add('Access-Control-Allow-Origin', '*')
          ..add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
          ..add('Access-Control-Allow-Headers', 'Content-Type, Authorization, Mcp-Session-Id');
        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          continue;
        }
        sseManager.handleRequest(request).catchError((e) {
          stderr.writeln('[apidash_mcp] SSE error: $e');
        });
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    }

  } else {
    final transport = await setupRequestRouter(server);
    final httpServer = await HttpServer.bind('localhost', port);
    stderr.writeln('[apidash_mcp] HTTP server → http://localhost:$port/mcp');
    stderr.writeln('mcp.json config:\n{\n  "servers": {\n    "apidash-mcp": {\n      "type": "http",\n      "url": "http://localhost:$port/mcp"\n    }\n  }\n}');
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

      if (path.startsWith('/mcp')) {
        if (!await _checkAuth(request, oauthMode: oauthMode, staticToken: staticToken)) continue;
        transport.handleRequest(request).catchError((e) {
          stderr.writeln('[apidash_mcp] HTTP error: $e');
        });
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    }
  }
}
