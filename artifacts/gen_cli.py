import json

dart_code = r'''import 'dart:io';
import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import 'dart:math' as math;

const reset  = '\x1B[0m';
const bold   = '\x1B[1m';
const green  = '\x1B[32m';
const yellow = '\x1B[33m';
const blue   = '\x1B[34m';
const red    = '\x1B[31m';
const magenta = '\x1B[35m';
const cyan   = '\x1B[36m';
const gray   = '\x1B[90m';
const bgYellow = '\x1B[43m';
const clearScreen = '\x1B[2J\x1B[H';

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

String colorMethod(String method) {
  switch (method.toUpperCase()) {
    case 'GET': return '$green$method$reset';
    case 'POST': return '$yellow$method$reset';
    case 'PUT': return '$blue$method$reset';
    case 'DELETE': return '$red$method$reset';
    case 'PATCH': return '$magenta$method$reset';
    default: return '$cyan$method$reset';
  }
}

String truncate(String text, int length) {
  if (text.length > length) return text.substring(0, length - 1) + '…';
  return text.padRight(length);
}

void printHelp() {
  print("""$bold╔═══════════════════════════════════════════════╗
║         🚀 APIDash CLI v0.5.0                 ║
╚═══════════════════════════════════════════════╝$reset

USAGE
  $cyan apidash <command> [options]$reset

COMMANDS
  $green run$reset          Execute a standalone HTTP request
  $green send$reset         Execute a saved request by ID or name
  $green list$reset         List all saved requests
  $green envs$reset         List all saved environments
  $green search$reset       Search for saved requests
  $green interactive$reset  Launch interactive TUI mode

EXAMPLES
  apidash run --url https://api.github.com/users/octocat
  apidash run --method POST --url https://httpbin.org/post --body '{"x":1}'
  apidash send --name "Get Users"
  apidash list --filter GET
  apidash search github
  apidash interactive""");
}

void printRunHelp() {
  print("""Usage: apidash run [options]

Options:
  --url, -u        URL (required)
  --method, -m     HTTP method (default GET)
  --header, -H     "Key: Value" format (repeatable)
  --body, -b       Request body string
  --timeout, -t    Timeout ms (default 30000)
  --output, -o     pretty (default) | json | minimal""");
}

void printListHelp() {
  print("""Usage: apidash list [options]

Options:
  --filter, -f     Filter by method (e.g. GET, POST)
  --search         Filter by keyword
  --json           Output as JSON array""");
}

void printSendHelp() {
  print("""Usage: apidash send [options]

Options:
  --id             Request ID
  --name           Request name (case-insensitive)
  --interactive    Interactive selection mode
  --output, -o     pretty (default) | json | minimal""");
}

void printBeautifulResponse(Map<String, dynamic> result) {
  final data = result['data'] as Map<String, dynamic>? ?? {};
  final success = result['success'] as bool? ?? false;
  final status = data['status'] as int? ?? 0;
  final statusText = data['statusText'] as String? ?? 'Error';
  final duration = data['duration'] as int? ?? 0;
  final body = data['body'] as String? ?? '';
  final reqModel = data['requestModel'] as Map? ?? {};
  
  final method = reqModel['method']?.toString().toUpperCase() ?? 'GET';
  final url = reqModel['url']?.toString() ?? '';
  final headers = data['headers'] as Map? ?? {};

  final width = math.max(60, stdout.hasTerminal ? stdout.terminalColumns : 80);
  final topBorder = '┌─ Response ${"─" * (width - 13)}┐';
  final rowLeft = '│';
  final rowRight = '│';

  final emoji = success ? '✅' : '❌';
  String colorStatus = red;
  if (status >= 200 && status < 300) colorStatus = green;
  else if (status >= 400 && status < 500) colorStatus = yellow;

  print(topBorder);
  
  final statusLine = '  $emoji $colorStatus$status $statusText$reset';
  final durationText = '· ${duration}ms';
  // rough padding calc
  int statusLen = 4 + status.toString().length + 1 + statusText.length;
  int padLen = width - statusLen - durationText.length - 6;
  if (padLen < 0) padLen = 0;
  print('│' + statusLine + " " * padLen + gray + durationText + reset + '   │');
  
  final urlLine = '  $bold$method$reset $url';
  int urlLen = 2 + method.length + 1 + url.length;
  int padUrl = width - urlLen - 4;
  if (padUrl < 0) padUrl = 0;
  // Let truncate handle long urls
  if (urlLen > width - 4) {
    print('│  $bold$method$reset ${truncate(url, width - method.length - 8)} │');
  } else {
    print('│' + urlLine + " " * padUrl + ' │');
  }

  print('├─ Headers ${"─" * (width - 12)}┤');
  headers.forEach((k, v) {
    String hl = '  $cyan$k$reset: $v';
    int hlen = 2 + k.toString().length + 2 + v.toString().length;
    if (hlen > width - 4) {
      print('│  $cyan$k$reset: ${truncate(v.toString(), width - k.toString().length - 8)} │');
    } else {
      print('│' + hl + " " * (width - hlen - 4) + ' │');
    }
  });

  print('├─ Body ${"─" * (width - 9)}┤');
  try {
    final decoded = jsonDecode(body);
    final pretty = JsonEncoder.withIndent('  ').convert(decoded);
    for (final line in pretty.split('\n')) {
      int llen = line.length;
      if (llen > width - 4) {
        print('│  ${truncate(line, width - 6)} │');
      } else {
        print('│  $line' + " " * (width - llen - 4) + ' │');
      }
    }
  } catch (_) {
    for (final line in body.split('\n')) {
      int llen = line.length;
      if (llen > width - 4) {
        print('│  ${truncate(line, width - 6)} │');
      } else {
        print('│  $line' + " " * (width - llen - 4) + ' │');
      }
    }
  }
  print('└${"─" * (width - 2)}┘');
}

void printResult(Map<String, dynamic> result, String outputOpt) {
  if (outputOpt == 'json') {
    print(jsonEncode(result));
    final success = result['success'] as bool? ?? false;
    final status = (result['data'] as Map?)?['status'] as int? ?? 0;
    if (!success || status >= 400) exit(1);
    exit(0);
  } else if (outputOpt == 'minimal') {
    final data = result['data'] as Map<String, dynamic>? ?? {};
    final status = data['status'] as int? ?? 0;
    final body = data['body'] as String? ?? '';
    print('$status $body');
    final success = result['success'] as bool? ?? false;
    if (!success || status >= 400) exit(1);
    exit(0);
  } else {
    printBeautifulResponse(result);
    final success = result['success'] as bool? ?? false;
    final status = (result['data'] as Map?)?['status'] as int? ?? 0;
    if (!success || status >= 400) exit(1);
    exit(0);
  }
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

void printBeautifulList(List<Map<String, dynamic>> results, {String? searchString}) {
  final width = math.max(60, stdout.hasTerminal ? stdout.terminalColumns : 80);
  print('  ┌${"─" * (width - 4)}┐');
  print('  │  📋 $bold APIDash Workspace — ${results.length} requests$reset' + " "*(width - 39 - results.length.toString().length) + '│');
  print('  ├──────┬──────────┬──────────────────────┬${"─" * (width - 43)}┤');
  print('  │  #   │ METHOD   │ NAME                 │ URL' + " "*(width-47) + '│');
  print('  ├──────┼──────────┼──────────────────────┼${"─" * (width - 43)}┤');
  
  for (int i = 0; i < results.length; i++) {
    final r = results[i];
    final m = r['method']?.toString().toUpperCase() ?? 'GET';
    final rawN = r['name']?.toString() ?? '';
    final rawU = r['url']?.toString() ?? '';
    
    String nText = truncate(rawN, 20);
    String uText = truncate(rawU, width - 46);
    String nPrint = padRight(nText, 20);
    String uPrint = uText.padRight(width - 46);

    if (searchString != null && searchString.isNotEmpty) {
      final normSearch = searchString.toLowerCase();
      if (nPrint.toLowerCase().contains(normSearch)) {
        int idx = nPrint.toLowerCase().indexOf(normSearch);
        nPrint = nPrint.substring(0, idx) + bgYellow + red + nPrint.substring(idx, idx+searchString.length) + reset + nPrint.substring(idx+searchString.length);
      }
      if (uPrint.toLowerCase().contains(normSearch)) {
        int idx = uPrint.toLowerCase().indexOf(normSearch);
        uPrint = uPrint.substring(0, idx) + bgYellow + red + uPrint.substring(idx, idx+searchString.length) + reset + uPrint.substring(idx+searchString.length);
      }
    }

    final idStr = padRight((i+1).toString(), 4);
    final mPrint = colorMethod(padRight(m, 8));
    print('  │ $idStr │ $mPrint │ $nPrint │ $uPrint │');
  }
  print('  └──────┴──────────┴──────────────────────┴${"─" * (width - 43)}┘');
}

Future<void> handleList(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    printListHelp();
    exit(0);
  }

  bool isJson = args.contains('--json');
  String? filter;
  String? searchString;
  for (int i = 0; i < args.length; i++) {
    if ((args[i] == '--filter' || args[i] == '-f') && i + 1 < args.length) {
      filter = args[++i].toUpperCase();
    }
    if ((args[i] == '--search') && i + 1 < args.length) {
      searchString = args[++i];
    }
  }

  await loadHiveIntoWorkspace();
  final reqs = WorkspaceState().requests;
  final results = <Map<String, dynamic>>[];

  for (final r in reqs) {
    final method = r['method']?.toString().toUpperCase() ?? 'GET';
    if (filter != null && method != filter) continue;
    
    if (searchString != null) {
      final s = searchString.toLowerCase();
      final n = r['name']?.toString().toLowerCase() ?? '';
      final u = r['url']?.toString().toLowerCase() ?? '';
      if (!n.contains(s) && !u.contains(s) && !method.contains(s)) continue;
    }
    
    results.add(r);
  }

  if (isJson) {
    print(jsonEncode(results));
    exit(0);
  }

  printBeautifulList(results, searchString: searchString);
}


Future<void> handleSearch(List<String> args) async {
  if (args.isEmpty) {
    print("Usage: apidash search <terms>");
    exit(0);
  }

  await loadHiveIntoWorkspace();
  final reqs = WorkspaceState().requests;
  final results = <Map<String, dynamic>>[];

  for (final r in reqs) {
    final method = r['method']?.toString().toUpperCase() ?? 'GET';
    final n = r['name']?.toString().toLowerCase() ?? '';
    final u = r['url']?.toString().toLowerCase() ?? '';
    final id = r['id']?.toString().toLowerCase() ?? '';

    bool matchAll = true;
    for (final term in args) {
      final s = term.toLowerCase();
      if (!n.contains(s) && !u.contains(s) && !method.contains(s) && !id.contains(s)) {
        matchAll = false;
        break;
      }
    }
    if (matchAll) results.add(r);
  }

  if (results.isEmpty) {
    print("No requests found matching '${args.join(' ')}'");
    exit(0);
  }

  printBeautifulList(results);
}


Future<void> handleInteractiveSend(List<Map<String, dynamic>> reqs) async {
   printBeautifulList(reqs);
   stdout.write("\nSelect request number: ");
   final input = stdin.readLineSync();
   final num = int.tryParse(input ?? '');
   if (num == null || num < 1 || num > reqs.length) {
     print("Invalid selection.");
     exit(1);
   }
   
   final req = reqs[num - 1];
   print("\nSelected: ${req['name']} [${req['method']}] ${req['url']}");
   stdout.write("Send this request? [Y/n] ");
   final conf = stdin.readLineSync()?.toLowerCase() ?? '';
   if (conf == 'n' || conf == 'no') {
     print("Cancelled.");
     exit(0);
   }

   final ctx = HttpRequestContext(
      method: req['method']?.toString() ?? 'GET',
      url: req['url']?.toString() ?? '',
      headers: (req['headers'] as Map?)?.cast<String, String>(),
      body: req['body']?.toString(),
      timeoutMs: 30000,
   );
   final result = await executeHttpRequest(ctx);
   printBeautifulResponse(result);
   exit(0);
}

Future<void> handleSend(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    printSendHelp();
    exit(0);
  }

  bool isInteractive = args.contains('--interactive');
  String? id;
  String? name;
  String output = 'pretty';

  for (int i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--id' && i + 1 < args.length) id = args[++i];
    else if (a == '--name' && i + 1 < args.length) name = args[++i];
    else if ((a == '--output' || a == '-o') && i + 1 < args.length) output = args[++i];
  }

  await loadHiveIntoWorkspace();
  final reqs = WorkspaceState().requests;

  if (isInteractive) {
    await handleInteractiveSend(reqs);
    return;
  }

  if (id == null && name == null) {
    stderr.writeln('Error: Must provide --id or --name, or use --interactive.');
    exit(1);
  }

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

  final width = math.max(60, stdout.hasTerminal ? stdout.terminalColumns : 80);
  
  print('  ┌${"─" * (width - 4)}┐');
  print('  │  🌍 $bold Environments — ${envs.length} total$reset' + " " * (width - 25 - envs.length.toString().length) + '│');
  print('  ├────────────────┬────────────────┬${"─" * (width - 37)}┤');
  print('  │  NAME          │  VARIABLES     │  VALUES' + " " * (width - 44) + '│');
  print('  ├────────────────┼────────────────┼${"─" * (width - 37)}┤');

  for (final e in envs) {
    final n = e['name']?.toString() ?? '';
    final vals = e['values'];
    List<Map<String, String>> vars = [];
    
    if (vals is List) {
      for (final v in vals) {
        if (v is Map && v['key'] != null) {
           String val = v['value']?.toString() ?? '';
           if (v['isSecret'] == true) val = '••••••••';
           vars.add({'key': v['key'].toString(), 'val': val});
        }
      }
    } else if (vals is Map) {
      vals.forEach((k, v) {
         vars.add({'key': k.toString(), 'val': v.toString()});
      });
    }

    String nPrint = padRight(truncate(n, 14), 14);
    if (vars.isEmpty) {
       print('  │ $nPrint │ ${padRight("", 14)} │ ${"".padRight(width - 39)} │');
    } else {
       for (int i = 0; i < vars.length; i++) {
         String nameCol = i == 0 ? nPrint : padRight("", 14);
         String keyCol = padRight(truncate(vars[i]['key']!, 14), 14);
         String valCol = truncate(vars[i]['val']!, width - 39).padRight(width - 39);
         print('  │ $nameCol │ $keyCol │ $valCol │');
       }
    }
  }
  print('  └────────────────┴────────────────┴${"─" * (width - 37)}┘');
}

String padRight(String text, int length) {
  if (text.length > length) return text.substring(0, length - 1) + ' ';
  return text.padRight(length);
}

void tuiReadChar() {
   stdin.echoMode = false;
   stdin.lineMode = false;
}
void tuiRestoreChar() {
   stdin.echoMode = true;
   stdin.lineMode = true;
}

Future<void> runInteractive() async {
  if (!stdout.hasTerminal) {
    print("Interactive mode requires a terminal.");
    exit(1);
  }

  await loadHiveIntoWorkspace();
  List<Map<String, dynamic>> reqs = WorkspaceState().requests;
  String searchTerm = "";
  int selectedReq = 0;
  
  String currentView = 'menu'; // menu, list
  
  stdin.echoMode = false;
  stdin.lineMode = false;

  void render() {
    print(clearScreen);
    if (currentView == 'menu') {
      print("""  ╔═══════════════════════════════════════╗
  ║         🚀 APIDash CLI v0.5.0         ║
  ║   API Testing from your Terminal      ║
  ╚═══════════════════════════════════════╝

  [1] Browse Requests    [2] Run Request
  [3] Environments       [4] Search
  [5] Quick Send         [Q] Quit""");
    } else if (currentView == 'list') {
      final results = <Map<String, dynamic>>[];
      for (final r in reqs) {
         final n = r['name']?.toString().toLowerCase() ?? '';
         if (searchTerm.isEmpty || n.contains(searchTerm.toLowerCase())) {
            results.add(r);
         }
      }
      
      printBeautifulList(results, searchString: searchTerm);
      if (searchTerm.isNotEmpty) {
          print("\n  🔍 Search: $searchTerm");
      }
      print("\n  [↑/↓] Navigate  [ENTER] Run  [/] Search  [ESC] Menu / Clear Search");
    }
  }

  render();

  await for (var key in stdin) {
     if (key.isEmpty) continue;
     
     if (currentView == 'menu') {
        int k = key[0];
        if (k == 113 || k == 81) { // q or Q
           break;
        } else if (k == 49) { // 1
           currentView = 'list';
           render();
        }
     } else if (currentView == 'list') {
        int k = key[0];
        if (k == 27) { // ESC
           if (searchTerm.isNotEmpty) {
               searchTerm = '';
           } else {
               currentView = 'menu';
           }
           render();
        } else if (k == 47) { // /
           stdout.write('\x1b[2J\x1b[H');
           printBeautifulList(reqs);
           stdout.write("\n  🔍 Search: \x1b[?25h");
           tuiRestoreChar();
           searchTerm = stdin.readLineSync() ?? '';
           tuiReadChar();
           print("\x1b[?25l");
           render();
        }
     }
  }
  
  tuiRestoreChar();
  print(clearScreen);
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
      case 'search':
        await handleSearch(restArgs);
        break;
      case 'interactive':
      case 'tui':
      case 'i':
        await runInteractive();
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
'''

with open('gen_cli.py_out.dart', 'w') as f:
    f.write(dart_code)

