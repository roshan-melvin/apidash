import 'dart:io';
import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';

const String kDataBox = 'apidash-data';
const String kEnvironmentBox = 'apidash-environments';
const String kKeyDataBoxIds = 'ids';
const String kKeyEnvBoxIds = 'environmentIds';

String _resolvePath() {
  String defaultPath;
  String? prefsPath;

  if (Platform.isLinux) {
    defaultPath = '${Platform.environment['HOME']}/.local/share/apidash';
    final linuxPref = '${Platform.environment['HOME']}/.local/share/com.example.apidash/shared_preferences.json';
    if (File(linuxPref).existsSync()) prefsPath = linuxPref;
  } else if (Platform.isMacOS) {
    defaultPath = '${Platform.environment['HOME']}/Library/Application Support/apidash';
  } else if (Platform.isWindows) {
    defaultPath = '${Platform.environment['LOCALAPPDATA']}\\apidash';
  } else {
    throw UnsupportedError('Unsupported platform');
  }

  if (prefsPath != null && File(prefsPath).existsSync()) {
    try {
      final content = File(prefsPath).readAsStringSync();
      final map = jsonDecode(content) as Map;
      final settingsRaw = map['flutter.apidash-settings'];
      if (settingsRaw is String) {
        final settings = jsonDecode(settingsRaw) as Map;
        final overridePath = settings['workspaceFolderPath'];
        if (overridePath is String && overridePath.isNotEmpty) {
          return overridePath;
        }
      }
    } catch (_) {}
  }
  return defaultPath;
}

Future<void> initHive() async {
  final hivePath = _resolvePath();
  try {
    Hive.init(hivePath);
    await Hive.openBox(kDataBox);
    await Hive.openBox(kEnvironmentBox);
  } catch (e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('lock') || msg.contains('hivelockerror')) {
      stderr.writeln('Error: APIDash GUI is currently running. Please close the main application to use the CLI.');
      exit(1);
    }
    stderr.writeln('Failed to open Hive at $hivePath: $e');
    exit(1);
  }
}

Future<void> loadHiveIntoWorkspace() async {
  String defaultPath;
  if (Platform.isLinux) {
    defaultPath = '${Platform.environment['HOME']}/.local/share/apidash';
  } else if (Platform.isMacOS) {
    defaultPath = '${Platform.environment['HOME']}/Library/Application Support/apidash';
  } else if (Platform.isWindows) {
    defaultPath = '${Platform.environment['LOCALAPPDATA']}\\apidash';
  } else {
    throw UnsupportedError('Unsupported platform');
  }

  final workspaceFile = File('$defaultPath/apidash_mcp_workspace.json');
  if (workspaceFile.existsSync()) {
    try {
      final json = jsonDecode(workspaceFile.readAsStringSync());
      
      final List<Map<String, dynamic>> requests = [];
      if (json['requests'] is List) {
        for (final req in json['requests']) {
          if (req is Map) {
            requests.add({
              'id': req['id']?.toString() ?? '',
              'name': req['name']?.toString() ?? '',
              'method': (req['method'] ?? 'GET').toString().toUpperCase(),
              'url': req['url']?.toString() ?? '',
              'headers': req['headers'] ?? <String, String>{},
              'body': req['body'],
            });
          }
        }
      }
      
      final List<Map<String, dynamic>> envs = [];
      if (json['environments'] is List) {
        for (final env in json['environments']) {
          if (env is Map) {
            envs.add(Map<String, dynamic>.from(env));
          }
        }
      }

      final store = WorkspaceState();
      store.updateRequests(requests);
      store.updateEnvironments(envs);
      return; 
    } catch (_) {}
  }

  await initHive();
  
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
          'id':             m['id'] ?? id.toString(),
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
}

void printHelp() {
  print('''
APIDash CLI

Usage: apidash <command> [options]

Commands:
  run     Execute a standalone HTTP request
  list    List all saved requests from your workspace
  send    Execute a saved request by ID or Name
  envs    List all saved environments

Run "apidash <command> --help" for more details.
''');
}

void printRunHelp() {
  print('''
Usage: apidash run [options]

Options:
  --url, -u        URL (required)
  --method, -m     HTTP method (default GET)
  --header, -H     "Key: Value" format (repeatable)
  --body, -b       Request body string
  --timeout, -t    Timeout ms (default 30000)
  --output, -o     pretty (default) | json | minimal
''');
}

void printListHelp() {
  print('''
Usage: apidash list [options]

Options:
  --filter, -f     Filter by method (e.g. GET, POST)
  --json           Output as JSON array
''');
}

void printSendHelp() {
  print('''
Usage: apidash send [options]

Options:
  --id             Request ID
  --name           Request name (case-insensitive)
  --output, -o     pretty (default) | json | minimal
''');
}

String padRight(String text, int length) {
  if (text.length > length) return text.substring(0, length - 1) + ' ';
  return text.padRight(length);
}

void printResult(Map<String, dynamic> result, String outputOpt) {
  final data = result['data'] as Map<String, dynamic>? ?? {};
  final success = result['success'] as bool? ?? false;
  final status = data['status'] as int? ?? 0;
  final statusText = data['statusText'] as String? ?? 'Error';
  final duration = data['duration'] as int? ?? 0;
  final body = data['body'] as String? ?? '';

  if (outputOpt == 'json') {
    print(jsonEncode(result));
  } else if (outputOpt == 'minimal') {
    print('$status $body');
  } else {
    // Pretty
    final emoji = success ? '✅' : '❌';
    String colorReset = '\x1B[0m';
    String colorStatus = '\x1B[31m'; // Red
    if (status >= 200 && status < 300) colorStatus = '\x1B[32m'; // Green
    else if (status >= 400 && status < 500) colorStatus = '\x1B[33m'; // Yellow

    print('$emoji $colorStatus$status $statusText$colorReset · ${duration}ms');
    
    // Print body safely
    try {
      final decoded = jsonDecode(body);
      print(JsonEncoder.withIndent('  ').convert(decoded));
    } catch (_) {
      print(body);
    }
  }

  if (!success || status >= 400) exit(1);
  exit(0);
}

Future<void> handleRun(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    printRunHelp();
    exit(0);
  }

  String? url;
  String method = 'GET';
  String? body;
  int timeout = 30000;
  String output = 'pretty';
  final Map<String, String> headers = {};

  for (int i = 0; i < args.length; i++) {
    final a = args[i];
    if ((a == '--url' || a == '-u') && i + 1 < args.length) url = args[++i];
    else if ((a == '--method' || a == '-m') && i + 1 < args.length) method = args[++i].toUpperCase();
    else if ((a == '--body' || a == '-b') && i + 1 < args.length) body = args[++i];
    else if ((a == '--timeout' || a == '-t') && i + 1 < args.length) timeout = int.tryParse(args[++i]) ?? 30000;
    else if ((a == '--output' || a == '-o') && i + 1 < args.length) output = args[++i];
    else if ((a == '--header' || a == '-H') && i + 1 < args.length) {
      final h = args[++i];
      final parts = h.split(':');
      if (parts.length >= 2) {
        headers[parts[0].trim()] = parts.sublist(1).join(':').trim();
      }
    }
  }

  if (url == null) {
    stderr.writeln('Error: Missing --url argument.\nHint: apidash run --url https://httpbin.org/get');
    exit(1);
  }

  final ctx = HttpRequestContext(
    method: method,
    url: url,
    headers: headers,
    body: body,
    timeoutMs: timeout,
  );

  final result = await executeHttpRequest(ctx);
  printResult(result, output);
}

Future<void> handleList(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    printListHelp();
    exit(0);
  }

  bool isJson = args.contains('--json');
  String? filter;
  for (int i = 0; i < args.length; i++) {
    if ((args[i] == '--filter' || args[i] == '-f') && i + 1 < args.length) {
      filter = args[++i].toUpperCase();
    }
  }

  await loadHiveIntoWorkspace();
  final reqs = WorkspaceState().requests;
  final results = [];

  for (final r in reqs) {
    final method = r['method']?.toString().toUpperCase() ?? 'GET';
    if (filter != null && method != filter) continue;
    results.add(r);
  }

  if (isJson) {
    print(jsonEncode(results));
    exit(0);
  }

  print('\x1B[1m${padRight("ID", 36)} ${padRight("METHOD", 9)} ${padRight("NAME", 20)} URL\x1B[0m');
  for (final r in results) {
    final id = r['id']?.toString() ?? '';
    final m = r['method']?.toString() ?? 'GET';
    final n = r['name']?.toString() ?? '';
    final u = r['url']?.toString() ?? '';
    print('${padRight(id, 36)} ${padRight(m, 9)} ${padRight(n, 20)} $u');
  }
}

Future<void> handleSend(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    printSendHelp();
    exit(0);
  }

  String? id;
  String? name;
  String output = 'pretty';

  for (int i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--id' && i + 1 < args.length) id = args[++i];
    else if (a == '--name' && i + 1 < args.length) name = args[++i];
    else if ((a == '--output' || a == '-o') && i + 1 < args.length) output = args[++i];
  }

  if (id == null && name == null) {
    stderr.writeln('Error: Must provide --id or --name.');
    exit(1);
  }

  await loadHiveIntoWorkspace();
  final reqs = WorkspaceState().requests;
  Map<String, dynamic>? req;

  if (id != null) {
    for (final r in reqs) {
      if (r['id'] == id) {
        req = r;
        break;
      }
    }
    if (req == null) {
      stderr.writeln("Error: No request found with id '$id'");
      exit(1);
    }
  } else if (name != null) {
    final nlow = name.toLowerCase();
    for (final r in reqs) {
      if ((r['name']?.toString().toLowerCase() ?? '') == nlow) {
        req = r;
        break;
      }
    }
    if (req == null) {
      stderr.writeln("Error: No request found with name '$name'");
      exit(1);
    }
  }

  final ctx = HttpRequestContext(
    method: req!['method']?.toString() ?? 'GET',
    url: req['url']?.toString() ?? '',
    headers: (req['headers'] as Map?)?.cast<String, String>(),
    body: req['body']?.toString(),
    timeoutMs: 30000,
  );

  final result = await executeHttpRequest(ctx);
  printResult(result, output);
}

Future<void> handleEnvs(List<String> args) async {
  bool isJson = args.contains('--json');
  
  await loadHiveIntoWorkspace();
  final envs = WorkspaceState().environments;

  if (isJson) {
    print(jsonEncode(envs));
    exit(0);
  }

  print('\x1B[1m${padRight("ID", 36)} ${padRight("NAME", 18)} VARIABLES\x1B[0m');
  for (final e in envs) {
    final id = e['id']?.toString() ?? e['raw']?.toString() ?? '';
    final n = e['name']?.toString() ?? '';
    
    // Attempt to extract variables safely depending on Hive env format
    final vals = e['values'];
    List<String> keys = [];
    if (vals is List) {
      for (final v in vals) {
        if (v is Map && v['key'] != null) {
          keys.add(v['key'].toString());
        }
      }
    } else if (vals is Map) {
      keys = vals.keys.map((k) => k.toString()).toList();
    }
    
    print('${padRight(id, 36)} ${padRight(n, 18)} ${keys.join(", ")}');
  }
}

void main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') && args.length == 1) {
    printHelp();
    exit(0);
  }

  final command = args.first;
  final restArgs = args.sublist(1);

  try {
    switch (command) {
      case 'run':
        await handleRun(restArgs);
        break;
      case 'list':
        await handleList(restArgs);
        break;
      case 'send':
        await handleSend(restArgs);
        break;
      case 'envs':
        await handleEnvs(restArgs);
        break;
      default:
        stderr.writeln('Unknown command: $command');
        printHelp();
        exit(1);
    }
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
