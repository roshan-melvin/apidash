import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:hive_ce/hive.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import 'dart:math' as math;

const reset = '\x1B[0m';
const bold = '\x1B[1m';
const green = '\x1B[32m';
const yellow = '\x1B[33m';
const blue = '\x1B[34m';
const red = '\x1B[31m';
const magenta = '\x1B[35m';
const cyan = '\x1B[36m';
const gray = '\x1B[90m';
const bgYellow = '\x1B[43m';
const clearScreen = '\x1B[2J\x1B[3J\x1B[H';

const String kDataBox = 'apidash-data';
const String kEnvironmentBox = 'apidash-environments';
const String kKeyDataBoxIds = 'ids';
const String kKeyEnvBoxIds = 'environmentIds';

String _resolvePath() {
  String defaultPath;
  String? prefsPath;

  if (Platform.isLinux) {
    defaultPath = '${Platform.environment['HOME']}/.local/share/apidash';
    final linuxPref =
        '${Platform.environment['HOME']}/.local/share/com.example.apidash/shared_preferences.json';
    if (File(linuxPref).existsSync()) prefsPath = linuxPref;
  } else if (Platform.isMacOS) {
    defaultPath =
        '${Platform.environment['HOME']}/Library/Application Support/apidash';
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
      stderr.writeln(
        'Error: APIDash GUI is currently running. Please close the main application to use the CLI.',
      );
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
    defaultPath =
        '${Platform.environment['HOME']}/Library/Application Support/apidash';
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
  final envBox = Hive.box(kEnvironmentBox);

  final rawIds = dataBox.get(kKeyDataBoxIds);
  final List<Map<String, dynamic>> requests = [];
  if (rawIds is List) {
    for (final id in rawIds) {
      final raw = dataBox.get(id.toString());
      if (raw == null) continue;
      try {
        final m = Map<String, dynamic>.from(raw as Map);
        requests.add({
          'id': m['id'] ?? id.toString(),
          'name': m['name'] ?? '',
          'method': (m['httpRequestModel']?['method'] ?? 'GET')
              .toString()
              .toUpperCase(),
          'url': m['httpRequestModel']?['url'] ?? '',
          'headers':
              m['httpRequestModel']?['enabledHeadersMap'] ?? <String, String>{},
          'body': m['httpRequestModel']?['body'],
          'responseStatus': m['responseStatus'],
          'responseBody': m['httpResponseModel']?['body'],
          'isWorking': m['isWorking'] ?? false,
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
    case 'GET':
      return '$green$method$reset';
    case 'POST':
      return '$yellow$method$reset';
    case 'PUT':
      return '$blue$method$reset';
    case 'DELETE':
      return '$red$method$reset';
    case 'PATCH':
      return '$magenta$method$reset';
    default:
      return '$cyan$method$reset';
  }
}

String truncate(String text, int length) {
  if (length <= 0) return '';
  if (text.length > length)
    return text.substring(0, math.max(0, length - 1)) + '…';
  return text.padRight(length);
}

void printApidashLogo() {
  print('''
                          [38;2;169;201;250m⢀[0m[38;2;168;201;250m⣀[0m[38;2;168;201;250m⣀[0m
                         [38;2;170;202;250m⣰[0m[38;2;168;201;250m⣿[0m[38;2;168;201;250m⠟[0m[38;2;168;201;250m⣿[0m[38;2;169;202;250m⣧[0m
                       [38;2;168;201;250m⣠[0m[38;2;168;201;250m⣾[0m[38;2;168;201;250m⠟[0m[38;2;168;201;250m⠁[0m[38;2;168;201;250m⢀[0m[38;2;168;201;250m⣿[0m[38;2;168;201;250m⡇[0m
               [38;2;40;95;159m⢠[0m[38;2;40;95;159m⣤[0m[38;2;40;95;159m⣤[0m[38;2;40;95;159m⣤[0m[38;2;40;95;159m⣄[0m [38;2;168;201;250m⢀[0m[38;2;116;158;213m⣴[0m[38;2;104;148;204m⣿[0m[38;2;95;140;198m⣯[0m[38;2;40;95;159m⣤[0m[38;2;40;95;159m⣤[0m[38;2;82;130;189m⣼[0m[38;2;152;187;238m⣿[0m [38;2;40;95;159m⣤[0m[38;2;40;95;159m⣤[0m[38;2;40;95;159m⣤[0m[38;2;40;95;159m⣤[0m[38;2;40;95;159m⣤[0m[38;2;40;95;159m⡄[0m
              [38;2;40;95;159m⢠[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⠛[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;116;158;213m⣴[0m[38;2;168;201;250m⣿[0m[38;2;96;141;198m⢿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⠛[0m[38;2;40;95;159m⢻[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣷[0m [38;2;40;95;159m⠛[0m[38;2;40;95;159m⢻[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⠛[0m[38;2;40;95;159m⠃[0m
              [38;2;40;95;159m⣾[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣯[0m[38;2;40;95;159m⣤[0m[38;2;40;95;159m⣽[0m[38;2;40;95;159m⣿[0m[38;2;41;95;159m⣿[0m[38;2;168;201;250m⠁[0m[38;2;40;95;159m⢸[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣶[0m[38;2;40;95;159m⣾[0m[38;2;40;95;159m⣿[0m[38;2;46;99;161m⡿[0m  [38;2;40;95;159m⢸[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m
              [38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;58;110;172m⣟[0m[38;2;104;148;204m⣿[0m[38;2;72;121;181m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m [38;2;40;95;159m⢸[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⠉[0m[38;2;131;170;224m⢿[0m[38;2;136;174;227m⣿[0m[38;2;168;201;250m⣶[0m[38;2;168;201;250m⣶[0m[38;2;82;130;189m⣶[0m[38;2;58;110;172m⣾[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;82;130;189m⣶[0m[38;2;125;165;219m⣶[0m[38;2;168;201;250m⣄[0m
              [38;2;65;116;177m⢛[0m[38;2;104;148;204m⣿[0m[38;2;136;174;227m⣿[0m[38;2;168;201;250m⠋[0m[38;2;40;95;159m⠘[0m[38;2;40;95;159m⠛[0m[38;2;40;95;159m⠛[0m [38;2;40;95;159m⠘[0m[38;2;40;95;159m⠛[0m[38;2;40;95;159m⠛[0m     [38;2;40;95;159m⠛[0m[38;2;40;95;159m⠛[0m[38;2;40;95;159m⠛[0m[38;2;40;95;159m⠛[0m[38;2;84;131;189m⣛[0m[38;2;136;174;227m⣿[0m[38;2;168;201;250m⡿[0m
             [38;2;168;201;250m⣠[0m[38;2;168;201;250m⣾[0m[38;2;168;201;250m⠟[0m[38;2;168;201;250m⠁[0m               [38;2;174;204;250m⢠[0m[38;2;169;202;250m⣶[0m[38;2;168;201;250m⡿[0m[38;2;168;201;250m⠋[0m
         [38;2;40;95;159m⢰[0m[38;2;40;95;159m⣶[0m[38;2;40;95;159m⣶[0m[38;2;56;108;170m⣾[0m[38;2;69;119;180m⣿[0m[38;2;58;110;172m⣷[0m[38;2;40;95;159m⣦[0m[38;2;168;201;250m⣀[0m[38;2;168;201;250m⣀[0m[38;2;99;142;198m⣠[0m[38;2;40;95;159m⣶[0m[38;2;40;95;159m⣶[0m[38;2;40;95;159m⣶[0m[38;2;40;95;159m⣶[0m[38;2;40;95;159m⡄[0m [38;2;144;175;216m⢀[0m[38;2;40;95;159m⣴[0m[38;2;40;95;159m⣶[0m[38;2;40;95;159m⣶[0m[38;2;40;95;159m⣶[0m[38;2;40;95;159m⣶[0m[38;2;114;156;211m⣾[0m[38;2;168;201;250m⡿[0m[38;2;70;120;180m⣿[0m[38;2;40;95;159m⣶[0m[38;2;40;95;159m⡆[0m [38;2;40;95;159m⢰[0m[38;2;40;95;159m⣶[0m[38;2;40;95;159m⣶[0m
         [38;2;40;95;159m⢸[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⠉[0m[38;2;90;136;193m⠛[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;83;130;189m⡟[0m[38;2;168;201;250m⠛[0m[38;2;56;108;170m⣿[0m[38;2;40;95;159m⣿[0m[38;2;88;134;193m⣿[0m[38;2;88;134;193m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣷[0m[38;2;44;98;161m⡀[0m[38;2;43;97;160m⢸[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;52;104;165m⣯[0m[38;2;88;135;193m⣿[0m[38;2;104;148;204m⣿[0m[38;2;104;148;204m⡋[0m [38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣧[0m[38;2;40;95;159m⣤[0m[38;2;40;95;159m⣼[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m
         [38;2;40;95;159m⢸[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m  [38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⡇[0m[38;2;40;95;159m⢸[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;72;121;181m⣿[0m[38;2;58;110;172m⣷[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⡇[0m [38;2;84;131;189m⣛[0m[38;2;73;122;182m⣿[0m[38;2;58;110;172m⡿[0m[38;2;40;95;159m⢿[0m[38;2;40;95;159m⣿[0m[38;2;42;96;160m⣿[0m [38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⡿[0m[38;2;40;95;159m⠿[0m[38;2;40;95;159m⢿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m
         [38;2;40;95;159m⢸[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;58;109;167m⣿[0m[38;2;48;101;163m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⡿[0m[38;2;40;95;159m⠁[0m[38;2;40;95;159m⢸[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;116;158;213m⡏[0m[38;2;40;95;159m⠉[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;84;131;189m⣧[0m[38;2;106;149;204m⣶[0m[38;2;51;104;167m⣿[0m[38;2;51;104;167m⣿[0m[38;2;58;109;167m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⡿[0m [38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⡇[0m [38;2;40;95;159m⢸[0m[38;2;40;95;159m⣿[0m[38;2;40;95;159m⣿[0m
         [38;2;40;95;159m⠈[0m[38;2;40;95;159m⠉[0m[38;2;40;95;159m⠉[0m[38;2;40;95;159m⠉[0m[38;2;40;95;159m⠉[0m[38;2;40;95;159m⠁[0m  [38;2;40;95;159m⠈[0m[38;2;131;170;224m⣽[0m[38;2;131;170;224m⡿[0m  [38;2;107;149;204m⣉[0m[38;2;131;170;224m⣽[0m[38;2;149;185;237m⡿[0m[38;2;168;201;250m⠋[0m[38;2;40;95;159m⠉[0m[38;2;40;95;159m⠉[0m[38;2;40;95;159m⠉[0m[38;2;40;95;159m⠉[0m[38;2;40;95;159m⠁[0m  [38;2;40;95;159m⠈[0m[38;2;40;95;159m⠉[0m[38;2;40;95;159m⠁[0m [38;2;58;108;167m⠈[0m[38;2;40;95;159m⠉[0m[38;2;40;95;159m⠉[0m
                 [38;2;168;201;250m⢰[0m[38;2;168;201;250m⣿[0m[38;2;168;201;250m⠃[0m[38;2;168;201;250m⢀[0m[38;2;169;202;250m⣶[0m[38;2;168;201;250m⡿[0m[38;2;168;201;250m⠋[0m
                 [38;2;168;201;250m⠸[0m[38;2;168;201;250m⣿[0m[38;2;169;201;250m⣾[0m[38;2;168;201;250m⡿[0m[38;2;168;201;250m⠋[0m
                        [90mhttps://github.com/foss42/apidash[0m

''');
}

void printHelp() {
  printApidashLogo();
  print("""USAGE
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

Future<bool> _paginateLines(List<String> lines) async {
  if (!stdout.hasTerminal) {
    for (var l in lines) print(l);
    return false;
  }

  int termHeight = stdout.terminalLines;
  int pageSize = math.max(10, termHeight - 2);
  final total = lines.length;

  bool useAltScreen = total > termHeight - 2;

  if (useAltScreen) {
    stdout.write('\x1B[?1049h'); // Enter alternate screen buffer
    stdout.write('\x1B[?25l');   // Hide cursor
  }

  try {
    int i = 0;
    while (i < math.max(1, total)) {
      if (useAltScreen) {
        stdout.write('\x1B[2J\x1B[H'); // Clear alternate screen
      }

      int end = math.min(i + pageSize, total);
      if (!useAltScreen) {
        end = total; // Print everything sequentially if fits
      }
      
      for (int j = i; j < end; j++) {
        if (useAltScreen) {
          stdout.write('${lines[j]}\n');
        } else {
          print(lines[j]);
        }
      }

      if (!useAltScreen) {
        break; // we printed everything, exit paginator naturally!
      }

      final isLast = (i + pageSize) >= total;
      final isFirst = i == 0;

      if (isLast) {
        stdout.write('\x1B[33m-- End of output  [↑] prev  [q/Esc] back --\x1B[0m ');
      } else if (isFirst) {
        stdout.write('\x1B[33m-- [↵/↓] next page  [q/Esc] back --\x1B[0m ');
      } else {
        stdout.write('\x1B[33m-- [↵/↓] next  [↑] prev  [q/Esc] back --\x1B[0m ');
      }

      while (true) {
        final k = await _readKey();
        if (k == 'q' || k == 'esc') return true; 
        if ((k == 'enter' || k == 'down') && !isLast) {
          i += pageSize;
          break;
        }
        if (k == 'up' && !isFirst) {
          i -= pageSize;
          if (i < 0) i = 0;
          break;
        }
      }
    }
  } finally {
    if (useAltScreen) {
      stdout.write('\x1B[?1049l'); // Leave alternate screen
      stdout.write('\x1B[?25h');   // Restore cursor
    }
  }
  return false;
}

Future<void> printBeautifulResponse(Map<String, dynamic> result) async {
  final data = result['data'] as Map<String, dynamic>? ?? {};
  final success = result['success'] as bool? ?? false;
  final status = data['status'] as int? ?? 0;
  final statusText = data['statusText'] as String? ?? 'Error';
  final duration = data['duration'] as int? ?? 0;
  final body = data['body'] as String? ?? '';
  final reqModel = data['requestModel'] as Map? ?? {};

  final method = reqModel['method']?.toString().toUpperCase() ?? 'GET';
  final url = reqModel['url']?.toString() ?? '';
  final reqHeaders =
      (reqModel['headers'] as Map?)?.cast<String, String>() ?? {};
  final reqBody = reqModel['body']?.toString() ?? '';

  final resHeaders = (data['headers'] as Map?)?.cast<String, String>() ?? {};

  final totalCols = stdout.hasTerminal ? stdout.terminalColumns : 100;
  final width = math.max(60, totalCols);
  final leftW = (width / 2).floor() - 2;
  final rightW = width - leftW - 3;

  final emoji = success ? '✅' : '❌';
  String colorStatus = red;
  if (status >= 200 && status < 300)
    colorStatus = green;
  else if (status >= 400 && status < 500)
    colorStatus = yellow;

  List<String> getPrettyLines(String rawBody, int maxW) {
    List<String> lines = [];
    if (rawBody.trim().isEmpty) return lines;
    try {
      final decoded = jsonDecode(rawBody);
      final pretty = JsonEncoder.withIndent('  ').convert(decoded);
      for (final line in pretty.split('\n')) {
        lines.add(truncate(line, maxW));
      }
    } catch (_) {
      for (var line in rawBody.split('\n')) {
        line = line.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
        line = line.replaceAll(RegExp(r'[\x00-\x08\x0B-\x1F]'), '');
        if (line.isEmpty) {
          lines.add('');
          continue;
        }
        while (line.length > maxW && maxW > 0) {
          lines.add(line.substring(0, maxW));
          line = line.substring(maxW);
        }
        if (line.isNotEmpty) lines.add(line);
      }
    }
    return lines;
  }

  // Left Column (Request Metadata)
  List<String> leftMeta = [];
  leftMeta.add(
    '  $bold$method$reset ${truncate(url, math.max(0, leftW - method.length - 3)).trimRight()}',
  );
  if (reqHeaders.isNotEmpty) {
    leftMeta.add('  $cyan├─ Headers ${"─" * math.max(0, leftW - 13)}$reset');
    reqHeaders.forEach((k, v) {
      leftMeta.add(
        '  $cyan$k$reset: ${truncate(v.toString(), math.max(0, leftW - k.toString().length - 6)).trimRight()}',
      );
    });
  }

  // Right Column (Response Metadata)
  List<String> rightMeta = [];
  rightMeta.add(
    '  $emoji $colorStatus$status $statusText$reset · ${duration}ms',
  );
  if (resHeaders.isNotEmpty) {
    rightMeta.add('  $cyan├─ Headers ${"─" * math.max(0, rightW - 13)}$reset');
    resHeaders.forEach((k, v) {
      rightMeta.add(
        '  $cyan$k$reset: ${truncate(v.toString(), math.max(0, rightW - k.toString().length - 6)).trimRight()}',
      );
    });
  }

  // Print side by side Metadata
  List<String> outBuf = [];
  final lBorder = '─ Request ${"─" * math.max(0, leftW - 10)}';
  final rBorder = '─ Response ${"─" * math.max(0, rightW - 11)}';
  outBuf.add('\n$cyan┌$lBorder┬$rBorder┐$reset');

  int maxMeta = math.max(leftMeta.length, rightMeta.length);
  for (int i = 0; i < maxMeta; i++) {
    String lText = i < leftMeta.length ? leftMeta[i] : '';
    String rText = i < rightMeta.length ? rightMeta[i] : '';

    int lVis = visibleLength(lText);
    String lPad = " " * math.max(0, leftW - lVis);

    int rVis = visibleLength(rText);
    String rPad = " " * math.max(0, rightW - rVis);

    outBuf.add('$cyan│$reset$lText$lPad$cyan│$reset$rText$rPad$cyan│$reset');
  }

  // Print Bodies as full width
  bool hasReqBody = reqBody.trim().isNotEmpty;
  bool hasResBody = body.trim().isNotEmpty;
  bool isHtml = resHeaders.entries.any(
    (e) =>
        e.key.toLowerCase() == 'content-type' &&
        e.value.toLowerCase().contains('text/html'),
  );

  if (hasReqBody || hasResBody) {
    outBuf.add('$cyan├${"─" * leftW}┴${"─" * rightW}┤$reset');
  } else {
    outBuf.add('$cyan└${"─" * leftW}┴${"─" * rightW}┘$reset');
  }

  int fullW = width - 2; // For actual text inside borders

  if (hasReqBody) {
    outBuf.add(
      '$cyan│$reset  $cyan├─ Request Body ${"─" * math.max(0, fullW - 18)}$reset$cyan│$reset',
    );
    final lines = getPrettyLines(reqBody, fullW - 2);
    for (var l in lines) {
      l = l.trimRight();
      String pad = " " * math.max(0, fullW - visibleLength('  $l'));
      outBuf.add('$cyan│$reset  $l$pad$cyan│$reset');
    }
    if (hasResBody) {
      outBuf.add('$cyan├${"─" * fullW}┤$reset');
    } else {
      outBuf.add('$cyan└${"─" * fullW}┘$reset');
    }
  }

  if (hasResBody) {
    outBuf.add(
      '$cyan│$reset  $cyan├─ Response Body ${"─" * math.max(0, fullW - 19)}$reset$cyan│$reset',
    );
    final lines = getPrettyLines(body, fullW - 2);
    int totalLines = lines.length;
    List<String> printLines = lines;
    bool truncated = false;

    if (isHtml) {
      String msg = '⚠ HTML response — showing raw source ($totalLines lines)';
      String paddedMsg = msg.padRight(fullW - 4);
      outBuf.add('$cyan│$reset  \x1B[33m$paddedMsg\x1B[0m  $cyan│$reset');
    }

    for (var l in printLines) {
      l = l.trimRight();
      String pad = " " * math.max(0, fullW - visibleLength('  $l'));
      outBuf.add('$cyan│$reset  $l$pad$cyan│$reset');
    }

    outBuf.add('$cyan└${"─" * fullW}┘$reset');
  }

  await _paginateLines(outBuf);
}

void printErrorFallback(String title, String message) {
  final width = math.max(60, stdout.hasTerminal ? stdout.terminalColumns - 6 : 100);
  final cleanTitle = title.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
  int borderLen = width - 5 - cleanTitle.length;
  if (borderLen < 0) borderLen = 0;
  
  print('');
  print('  $red┌─ $title $red${"─" * borderLen}┐$reset');
  for (String l in message.split('\n')) {
    final cleanLine = l.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
    final padStr = " " * math.max(0, width - 4 - cleanLine.length);
    print('  $red│$reset  $l$padStr$red│$reset');
  }
  print('  $red└${"─" * (width - 2)}┘$reset');
  print('');
}

Future<void> printResult(Map<String, dynamic> result, String outputOpt) async {
  if (outputOpt == 'json') {
    print(jsonEncode(result));
    final success = result['success'] as bool? ?? false;
    final status = (result['data'] as Map?)?['status'] as int? ?? 0;
    if (!success || status >= 400 || status == 0) exit(1);
    exit(0);
  } else if (outputOpt == 'minimal') {
    final data = result['data'] as Map<String, dynamic>? ?? {};
    final status = data['status'] as int? ?? 0;
    final body = data['body'] as String? ?? '';
    print('$status $body');
    final success = result['success'] as bool? ?? false;
    if (!success || status >= 400 || status == 0) exit(1);
    exit(0);
  } else {
    final success = result['success'] as bool? ?? false;
    final status = (result['data'] as Map?)?['status'] as int? ?? 0;
    
    if (!success || status == 0) {
      final data = result['data'] as Map<String, dynamic>? ?? {};
      final errMsg = data['statusText'] as String? ?? 'Network Error';
      printErrorFallback('\x1B[1m\x1B[31mRequest Failed\x1B[0m', 'Error: $errMsg');
      exit(1);
    }

    await printBeautifulResponse(result);
    if (status >= 400) exit(1);
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
    if ((a == '--url' || a == '-u') && i + 1 < args.length)
      url = args[++i];
    else if ((a == '--method' || a == '-m') && i + 1 < args.length)
      method = args[++i].toUpperCase();
    else if ((a == '--body' || a == '-b') && i + 1 < args.length)
      body = args[++i];
    else if ((a == '--timeout' || a == '-t') && i + 1 < args.length)
      timeout = int.tryParse(args[++i]) ?? 30000;
    else if ((a == '--output' || a == '-o') && i + 1 < args.length)
      output = args[++i];
    else if ((a == '--header' || a == '-H') && i + 1 < args.length) {
      final h = args[++i];
      final parts = h.split(':');
      if (parts.length >= 2) {
        headers[parts[0].trim()] = parts.sublist(1).join(':').trim();
      }
    }
  }

  if (url == null) {
    stderr.writeln(
      'Error: Missing --url argument.\nHint: apidash run --url https://httpbin.org/get',
    );
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
  await printResult(result, output);
}

void printBeautifulList(
  List<Map<String, dynamic>> results, {
  String? searchString,
}) {
  final width = math.max(80, stdout.hasTerminal ? stdout.terminalColumns : 100);
  print('  ┌${"─" * (width - 4)}┐');
  print(
    '  │  📋 $bold APIDash Workspace — ${results.length} requests$reset' +
        " " * (width - 38 - results.length.toString().length) +
        '│',
  );
  print('  ├──────┬──────────────┬──────────┬──────────────────────┬${"─" * (width - 60)}┤');
  print(
    '  │  #   │ ID           │ METHOD   │ NAME                 │ URL' +
        " " * (width - 65) +
        '│',
  );
  print('  ├──────┼──────────────┼──────────┼──────────────────────┼${"─" * (width - 60)}┤');

  for (int i = 0; i < results.length; i++) {
    final r = results[i];
    final m = r['method']?.toString().toUpperCase() ?? 'GET';
    final rawId = r['id']?.toString() ?? '';
    final rawN = r['name']?.toString() ?? '';
    final rawU = r['url']?.toString() ?? '';

    String idText = truncate(rawId, 12);
    String nText = truncate(rawN, 20);
    String uText = truncate(rawU, width - 62);
    String idPrint = padRight(idText, 12);
    String nPrint = padRight(nText, 20);
    String uPrint = uText.padRight(width - 62);

    if (searchString != null && searchString.isNotEmpty) {
      final normSearch = searchString.toLowerCase();
      if (nPrint.toLowerCase().contains(normSearch)) {
        int idx = nPrint.toLowerCase().indexOf(normSearch);
        nPrint =
            nPrint.substring(0, idx) +
            bgYellow +
            red +
            nPrint.substring(idx, idx + searchString.length) +
            reset +
            nPrint.substring(idx + searchString.length);
      }
      if (uPrint.toLowerCase().contains(normSearch)) {
        int idx = uPrint.toLowerCase().indexOf(normSearch);
        uPrint =
            uPrint.substring(0, idx) +
            bgYellow +
            red +
            uPrint.substring(idx, idx + searchString.length) +
            reset +
            uPrint.substring(idx + searchString.length);
      }
    }

    final idStr = padRight((i + 1).toString(), 4);
    final mPrint = colorMethod(padRight(m, 8));
    print('  │ $idStr │ $idPrint │ $mPrint │ $nPrint │ $uPrint │');
  }
  print('  └──────┴──────────────┴──────────┴──────────────────────┴${"─" * (width - 60)}┘');
}

Future<String?> handleList(
  List<String> args, {
  bool isStandalone = true,
}) async {
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

  return await _interactiveList(results, isStandalone: isStandalone);
}

Future<String?> _interactiveList(
  List<Map<String, dynamic>> allResults, {
  bool isStandalone = true,
}) async {
  if (!stdout.hasTerminal) {
    printBeautifulList(allResults);
    return null;
  }

  if (isStandalone) {
    stdout.write('\x1B[?1049h'); // Enter alternate screen buffer
  }

  _ensureStdinListening();
  stdout.write('\x1B[?25l'); // hide cursor

  String searchTerm = '';
  int selected = 0;
  int scrollOffset = 0;

  void draw() {
    stdout.write('\x1B[2J\x1B[H');

    // Filter results
    final filtered = searchTerm.isEmpty
        ? allResults
        : allResults.where((r) {
            final n = r['name']?.toString().toLowerCase() ?? '';
            final u = r['url']?.toString().toLowerCase() ?? '';
            final m = r['method']?.toString().toLowerCase() ?? '';
            final s = searchTerm.toLowerCase();
            return n.contains(s) || u.contains(s) || m.contains(s);
          }).toList();

    if (selected >= filtered.length)
      selected = math.max(0, filtered.length - 1);

    final colWidth = stdout.hasTerminal ? stdout.terminalColumns : 80;
    final width = math.max(70, colWidth - 1); // Avoid exact boundary wrapping
    final int termHeight = stdout.terminalLines;
    final int headerLines = 5;
    final int footerLines = 5;
    final int listHeight = math.max(3, termHeight - headerLines - footerLines);

    // Scroll offset
    if (selected >= scrollOffset + listHeight)
      scrollOffset = selected - listHeight + 1;
    if (selected < scrollOffset) scrollOffset = selected;

    final urlW = math.max(10, width - 62);

    // Single unified box header mirroring printBeautifulList
    stdout.write('  ${cyan}┌${"─" * math.max(1, width - 4)}┐${reset}\n');

    String title = '📋 APIDash Workspace — ${allResults.length} requests';
    if (searchTerm.isNotEmpty) {
      title += ' (Filter: "$searchTerm" - ${filtered.length} matches)';
    }

    // Calculate visible length accurately
    int titleVis = visibleLength(title);
    String titlePad = "".padRight(math.max(0, width - 4 - titleVis - 2));

    stdout.write(
      '  ${cyan}│${reset}  $bold$title$reset$titlePad${cyan}│${reset}\n',
    );
    stdout.write(
      '  ${cyan}├──────┬──────────────┬──────────┬──────────────────────┬${"─" * math.max(1, urlW + 2)}┤${reset}\n',
    );

    String hId = "  #   ";
    String hIdHash = " ID           ";
    String hMethod = " METHOD   ";
    String hName = " NAME                 ";
    String hUrl = " URL".padRight(urlW + 2);
    stdout.write(
      '  ${cyan}│${reset}$bold$hId$reset${cyan}│${reset}$bold$hIdHash$reset${cyan}│${reset}$bold$hMethod$reset${cyan}│${reset}$bold$hName$reset${cyan}│${reset}$bold$hUrl$reset${cyan}│${reset}\n',
    );
    stdout.write(
      '  ${cyan}├──────┼──────────────┼──────────┼──────────────────────┼${"─" * math.max(1, urlW + 2)}┤${reset}\n',
    );

    if (filtered.isEmpty) {
      stdout.write(
        '  ${cyan}│${reset}  ${yellow}No requests match "$searchTerm"${reset}${"".padRight(math.max(0, width - 6 - visibleLength('No requests match "$searchTerm"')))}${cyan}│${reset}\n',
      );
      // pad out remaining lines to keep layout height stable
      for (int pad = 1; pad < listHeight; pad++) {
        stdout.write(
          '  ${cyan}│${reset}${"".padRight(width - 4)}${cyan}│${reset}\n',
        );
      }
      stdout.write(
        '  ${cyan}└──────┴──────────────┴──────────┴──────────────────────┴${"─" * math.max(1, urlW + 2)}┘${reset}\n',
      );
      stdout.write('\n'); // hints placeholder
    } else {
      final endIdx = math.min(filtered.length, scrollOffset + listHeight);
      for (int i = scrollOffset; i < endIdx; i++) {
        final r = filtered[i];
        final m = r['method']?.toString().toUpperCase() ?? 'GET';
        final rawId = r['id']?.toString() ?? '';
        final rawN = r['name']?.toString() ?? '';
        final rawU = r['url']?.toString() ?? '';
        final idStr = padRight((i + 1).toString(), 4);
        final idPrint = padRight(truncate(rawId, 12), 12);
        final mPrint = colorMethod(padRight(m, 8));
        String nPrint = padRight(truncate(rawN, 20), 20);
        String uPrint = truncate(
          rawU,
          math.max(1, urlW),
        ).padRight(math.max(1, urlW));

        // Highlight search term in name and url
        if (searchTerm.isNotEmpty) {
          final s = searchTerm.toLowerCase();
          if (nPrint.toLowerCase().contains(s)) {
            final idx = nPrint.toLowerCase().indexOf(s);
            nPrint =
                nPrint.substring(0, idx) +
                bgYellow +
                red +
                nPrint.substring(idx, idx + s.length) +
                reset +
                nPrint.substring(idx + s.length);
          }
          if (uPrint.toLowerCase().contains(s)) {
            final idx = uPrint.toLowerCase().indexOf(s);
            uPrint =
                uPrint.substring(0, idx) +
                bgYellow +
                red +
                uPrint.substring(idx, idx + s.length) +
                reset +
                uPrint.substring(idx + s.length);
          }
        }

        if (i == selected) {
          stdout.write(
            '  ${cyan}│${reset}$bold ▶$idStr$reset${cyan}│${reset} $idPrint ${cyan}│${reset} $mPrint ${cyan}│${reset} $bold$nPrint$reset ${cyan}│${reset} $bold$uPrint$reset ${cyan}│${reset}\n',
          );
        } else {
          stdout.write(
            '  ${cyan}│${reset}  $idStr${cyan}│${reset} $idPrint ${cyan}│${reset} $mPrint ${cyan}│${reset} $nPrint ${cyan}│${reset} ${gray}$uPrint$reset ${cyan}│${reset}\n',
          );
        }
      }

      // pad if filtered list is shorter than listHeight
      for (int pad = endIdx - scrollOffset; pad < listHeight; pad++) {
        stdout.write(
          '  ${cyan}│${reset}${"".padRight(math.max(1, width - 4))}${cyan}│${reset}\n',
        );
      }

      stdout.write(
        '  ${cyan}└──────┴──────────────┴──────────┴──────────────────────┴${"─" * math.max(1, urlW + 2)}┘${reset}\n',
      );

      // Scroll hints
      final hints = <String>[];
      if (scrollOffset > 0) hints.add('↑ ${scrollOffset} more above');
      if (endIdx < filtered.length)
        hints.add('↓ ${filtered.length - endIdx} more below');

      if (hints.isNotEmpty) {
        stdout.write('  ${gray}${hints.join("   ")}${reset}\n');
      } else {
        stdout.write('\n'); // keep vertical height perfectly fixed
      }
    }

    // Footer
    stdout.write(
      '\n  ${gray}[↑/↓] Navigate  [/] Search  [Enter] Select  [Del] Delete  [ESC] Back${reset}\n',
    );
    stdout.write('  ${gray}Search:${reset} $green$searchTerm${reset}_');
  }

  try {
    draw();

    while (true) {
      final bytes = await _keyController.stream.first;
      if (bytes.isEmpty) continue;

      final b = bytes[0];

      if (b == 27 && bytes.length == 1) {
        // ESC — exit
        break;
      } else if (b == 13 || b == 10) {
        // Enter
        final filtered = searchTerm.isEmpty
            ? allResults
            : allResults.where((r) {
                final s = searchTerm.toLowerCase();
                return (r['name']?.toString().toLowerCase() ?? '').contains(
                      s,
                    ) ||
                    (r['url']?.toString().toLowerCase() ?? '').contains(s) ||
                    (r['method']?.toString().toLowerCase() ?? '').contains(s);
              }).toList();
        if (filtered.isNotEmpty && selected < filtered.length) {
          return filtered[selected]['id']?.toString() ??
              filtered[selected]['name']?.toString();
        }
        break;
      } else if (bytes.length == 3 && bytes[0] == 27 && bytes[1] == 91) {
        // Arrow keys
        if (bytes[2] == 65) {
          // Up
          if (selected > 0) selected--;
        } else if (bytes[2] == 66) {
          // Down
          final filtered = searchTerm.isEmpty
              ? allResults
              : allResults.where((r) {
                  final s = searchTerm.toLowerCase();
                  return (r['name']?.toString().toLowerCase() ?? '').contains(
                        s,
                      ) ||
                      (r['url']?.toString().toLowerCase() ?? '').contains(s) ||
                      (r['method']?.toString().toLowerCase() ?? '').contains(s);
                }).toList();
          if (selected < filtered.length - 1) selected++;
        }
      } else if (b == 127 || b == 8) {
        // Backspace
        if (searchTerm.isNotEmpty) {
          searchTerm = searchTerm.substring(0, searchTerm.length - 1);
          selected = 0;
        }
      } else if (b >= 32 && b < 127) {
        // Printable — add to search
        for (var byte in bytes) {
          if (byte >= 32 && byte < 127) {
            searchTerm += String.fromCharCode(byte);
          }
        }
        selected = 0;
      }

      draw();
    }
  } finally {
    stdout.write('\x1B[?25h'); // restore cursor
    if (isStandalone) {
      stdout.write('\x1B[?1049l'); // leave alternate screen
      _stopStdinListening();
    } else {
      stdout.write('\x1B[2J\x1B[H'); // clear inner menu
    }
  }
  return null;
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
      if (!n.contains(s) &&
          !u.contains(s) &&
          !method.contains(s) &&
          !id.contains(s)) {
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
    if (a == '--id' && i + 1 < args.length)
      id = args[++i];
    else if (a == '--name' && i + 1 < args.length)
      name = args[++i];
    else if ((a == '--output' || a == '-o') && i + 1 < args.length)
      output = args[++i];
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
      printErrorFallback('\x1B[1m\x1B[31mError\x1B[0m', "No request found with id '$id'");
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
      printErrorFallback('\x1B[1m\x1B[31mError\x1B[0m', "No request found with name '$name'");
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
  await printResult(result, output);
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
  print(
    '  │  🌍 $bold Environments — ${envs.length} total$reset' +
        " " * (width - 25 - envs.length.toString().length) +
        '│',
  );
  print('  ├────────────────┬────────────────┬${"─" * (width - 37)}┤');
  print(
    '  │  NAME          │  VARIABLES     │  VALUES' + " " * (width - 44) + '│',
  );
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
        String valCol = truncate(
          vars[i]['val']!,
          width - 39,
        ).padRight(width - 39);
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

int visibleLength(String s) {
  int len = s.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '').length;
  // Fix double-width emojis distorting padding by 1 char
  if (s.contains('✅') || s.contains('❌')) len += 1;
  return len;
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
  int scrollOffset = 0;
  Map<String, dynamic>? lastResult;
  String lastRequestMethod = 'GET';
  String lastRequestUrl = '';
  String quickRunUrl = '';

  String quickRunMethod = 'GET';
  List<String> responseLines = [];
  int responseScrollOffset = 0;

  String currentView = 'menu'; // menu, list, search, response, envs, quickrun

  try {
    stdin.echoMode = false;
    stdin.lineMode = false;
    stdout.write('\x1B[?25l'); // Hide cursor

    void render() {
      // CLEAR SCREEN + HOME
      stdout.write('\x1B[2J\x1B[3J\x1B[H');
      int height = stdout.terminalLines;
      int width = stdout.terminalColumns;

      if (currentView == 'menu') {
        printApidashLogo();
        print("""  [1] Browse & Run Requests
      ↑↓ navigate · ENTER run · / search

  [2] Environments
      view saved environments & variables

  [3] Quick Run
      type any URL and send instantly

  [Q] Quit""");

        stdout.write('\x1B[${height}H');
        stdout.write('  [1-3] Select option   [Q] Quit');
      } else if (currentView == 'response') {
        if (lastResult != null) {
          final data = lastResult!['data'] as Map<String, dynamic>? ?? {};
          final success = lastResult!['success'] as bool? ?? false;
          final status = data['status'] as int? ?? 0;
          final duration = data['duration'] as int? ?? 0;
          final method = lastRequestMethod;
          final url = lastRequestUrl;

          final emoji = success ? '✅' : '❌';
          String colorStatus = red;
          if (status >= 200 && status < 300)
            colorStatus = green;
          else if (status >= 400 && status < 500)
            colorStatus = yellow;

          print('┌─ Response ${"─" * (width - 13)}┐');
          print(
            '│  $emoji $colorStatus$status OK$reset · ${duration}ms' +
                ' ' *
                    (width -
                        18 -
                        status.toString().length -
                        duration.toString().length) +
                '│',
          );
          print(
            '│  $bold$method$reset ${truncate(url, width - method.length - 8).padRight(width - method.length - 8)} │',
          );
          print('├─ Headers ${"─" * (width - 12)}┤');

          final rawHeaders = data['headers'] as Map? ?? {};
          final lowerHeaders = rawHeaders.map(
            (k, v) => MapEntry(k.toString().toLowerCase(), v.toString()),
          );
          final importantKeys = [
            'content-type',
            'content-length',
            'server',
            'x-ratelimit-remaining',
            'x-request-id',
            'authorization',
            'cache-control',
            'location',
          ];

          bool hasNotable = false;
          for (final k in importantKeys) {
            if (lowerHeaders.containsKey(k)) {
              hasNotable = true;
              String val = lowerHeaders[k]!.trim();
              String line = '  $cyan$k$reset: $val';
              int visibleLen =
                  4 + k.length + val.length; // "  " + k + ": " + val
              int pad = width - visibleLen - 3;
              if (pad < 0) pad = 0;
              print('│' + line + " " * pad + '│');
            }
          }
          if (!hasNotable) {
            int pad = width - 23 - 3;
            if (pad < 0) pad = 0;
            print('│  (no notable headers)' + " " * pad + '│');
          }

          int bodyHeight = height - 9; // borders + headers max area approx
          if (bodyHeight < 5) bodyHeight = 5;
          String bodyIndicator =
              'Body (Line ${responseScrollOffset + 1}-${math.min(responseLines.length, responseScrollOffset + bodyHeight)} of ${responseLines.length})';
          print(
            '├─ $bodyIndicator ${"─" * math.max(0, width - bodyIndicator.length - 6)}┤',
          );

          for (int i = 0; i < bodyHeight; i++) {
            int idx = responseScrollOffset + i;
            if (idx < responseLines.length) {
              String line = responseLines[idx];
              print('│  ${line.padRight(width - 6)} │');
            }
          }
          print('└${"─" * (width - 2)}┘');
        }
        stdout.write('\x1B[${height}H');
        stdout.write('  [↑/↓] Scroll   [ESC] Back');
      } else if (currentView == 'list' || currentView == 'search') {
        final results = <Map<String, dynamic>>[];
        for (final r in reqs) {
          final n = r['name']?.toString().toLowerCase() ?? '';
          final u = r['url']?.toString().toLowerCase() ?? '';
          final m = r['method']?.toString().toLowerCase() ?? '';
          if (searchTerm.isEmpty ||
              n.contains(searchTerm.toLowerCase()) ||
              u.contains(searchTerm.toLowerCase()) ||
              m.contains(searchTerm.toLowerCase())) {
            results.add(r);
          }
        }

        if (selectedReq >= results.length)
          selectedReq = math.max(0, results.length - 1);

        int listHeight = math.max(1, height - 7); // updated height alloc
        if (scrollOffset > selectedReq) scrollOffset = selectedReq;
        if (selectedReq >= scrollOffset + listHeight)
          scrollOffset = selectedReq - listHeight + 1;
        if (scrollOffset > math.max(0, results.length - listHeight))
          scrollOffset = math.max(0, results.length - listHeight);

        if (currentView == 'search') {
          print("  🔍 Search: ${searchTerm}_");
        } else {
          print("  📋 $bold Browse Requests (${results.length})$reset\n");
        }

        int endIdx = math.min(results.length, scrollOffset + listHeight);

        for (int i = scrollOffset; i < endIdx; i++) {
          final r = results[i];
          final m = r['method']?.toString().toUpperCase() ?? 'GET';
          final rawN = r['name']?.toString() ?? '';
          final rawU = r['url']?.toString() ?? '';

          String mPad = padRight(m, 8);
          String nPad = padRight(truncate(rawN, 20), 20);
          String uPad = truncate(rawU, width - 36);

          if (searchTerm.isNotEmpty) {
            final s = searchTerm.toLowerCase();
            if (nPad.toLowerCase().contains(s)) {
              int idx = nPad.toLowerCase().indexOf(s);
              nPad =
                  nPad.substring(0, idx) +
                  '\x1B[43m\x1B[31m' +
                  nPad.substring(idx, idx + s.length) +
                  reset +
                  nPad.substring(idx + s.length);
            }
            if (uPad.toLowerCase().contains(s)) {
              int idx = uPad.toLowerCase().indexOf(s);
              uPad =
                  uPad.substring(0, idx) +
                  '\x1B[43m\x1B[31m' +
                  uPad.substring(idx, idx + s.length) +
                  reset +
                  uPad.substring(idx + s.length);
            }
          }

          if (i == selectedReq) {
            stdout.write(
              '▶ \x1B[1m${colorMethod(mPad)}\x1B[1m $nPad $rawU\x1B[0m\n',
            );
          } else {
            stdout.write('  ${colorMethod(mPad)} $nPad ${gray}$uPad$reset\n');
          }
        }

        // Scroll indicators
        if (results.length > listHeight) {
          String ind =
              "  " +
              (scrollOffset > 0 ? "↑ more  " : "") +
              " " +
              (endIdx < results.length
                  ? "↓ more (${results.length - endIdx} remaining)"
                  : "");
          stdout.write('\x1B[${height - 1}H' + ind);
        }

        stdout.write('\x1B[${height}H');
        if (currentView == 'search') {
          stdout.write(
            '  [ESC] Clear/Exit search   [ENTER] Select   Type to filter...',
          );
        } else {
          stdout.write('  [↑/↓] Navigate  [ENTER] Run  [/] Search  [ESC] Menu');
        }
      } else if (currentView == 'envs') {
        final wsFile = File(
          '${Platform.environment['HOME']}/.local/share/apidash/apidash_mcp_workspace.json',
        );
        List envs = [];
        if (wsFile.existsSync()) {
          try {
            final ws = jsonDecode(wsFile.readAsStringSync());
            envs = ws['environments'] as List? ?? [];
          } catch (_) {}
        }
        if (envs.isEmpty) envs = WorkspaceState().environments;

        stdout.write('  🌍 \x1B[1mEnvironments (${envs.length})\x1B[0m\n\n');
        if (envs.isEmpty) {
          stdout.write('  No environments found.\n');
          stdout.write(
            '  \x1B[90mCreate environments in the APIDash GUI first.\x1B[0m\n',
          );
        } else {
          for (final env in envs) {
            final name = env['name']?.toString() ?? 'Unknown';
            final values = (env['values'] as List?) ?? [];
            stdout.write('  \x1B[1m\x1B[36m$name\x1B[0m\n');
            if (values.isEmpty) {
              stdout.write('    \x1B[90m(no variables)\x1B[0m\n');
            }
            for (final v in values) {
              final key = v['key']?.toString() ?? '';
              final isSecret = v['secret'] == true;
              final enabled = v['enabled'] != false;
              final val = isSecret ? '••••••••' : v['value']?.toString() ?? '';
              final dim = enabled ? '' : ' \x1B[90m(disabled)\x1B[0m';
              stdout.write(
                '    \x1B[33m$key\x1B[0m = \x1B[32m$val\x1B[0m$dim\n',
              );
            }
            stdout.write('\n');
          }
        }
        stdout.write('\x1B[${height}H');
        stdout.write('  [ESC] Back to menu');
      } else if (currentView == 'quickrun') {
        stdout.write('  ⚡ \x1B[1mQuick Run\x1B[0m\n\n');
        String mColor = '\x1B[32m';
        if (quickRunMethod == 'POST')
          mColor = '\x1B[33m';
        else if (quickRunMethod == 'PUT')
          mColor = '\x1B[34m';
        else if (quickRunMethod == 'PATCH')
          mColor = '\x1B[35m';
        else if (quickRunMethod == 'DELETE')
          mColor = '\x1B[31m';
        stdout.write(
          '  Method : [$mColor\x1B[1m$quickRunMethod\x1B[0m]  ← TAB to cycle\n',
        );
        stdout.write('  URL    : \x1B[1m\x1B[36m${quickRunUrl}_\x1B[0m\n\n');
        stdout.write('  \x1B[90mExamples:\x1B[0m\n');
        stdout.write('  \x1B[90m  https://httpbin.org/get\x1B[0m\n');
        stdout.write(
          '  \x1B[90m  https://api.github.com/users/octocat\x1B[0m\n\n',
        );
        stdout.write('\x1B[${height}H');
        stdout.write('  [ENTER] Send   [ESC] Back to menu');
      }
    }

    render();

    await for (var keyBytes in stdin) {
      if (keyBytes.isEmpty) continue;

      if (currentView == 'response') {
        if (keyBytes.length == 3 && keyBytes[0] == 27 && keyBytes[1] == 91) {
          int bodyHeight = math.max(5, stdout.terminalLines - 9);
          if (keyBytes[2] == 65) {
            // Up
            if (responseScrollOffset > 0) responseScrollOffset--;
            render();
          } else if (keyBytes[2] == 66) {
            // Down
            if (responseScrollOffset < responseLines.length - bodyHeight)
              responseScrollOffset++;
            render();
          }
        } else if (keyBytes.length == 1 && keyBytes[0] == 27) {
          // ESC
          if (quickRunUrl.isNotEmpty) {
            currentView = 'quickrun';
            quickRunUrl = '';
            quickRunMethod = 'GET';
          } else {
            currentView = 'list';
          }
          render();
        }
        continue;
      }

      if (currentView == 'menu') {
        int k = keyBytes[0];
        if (k == 113 || k == 81 || k == 27) {
          // q or Q or ESC
          break;
        } else if (k == 49) {
          // 1 - Browse Requests
          currentView = 'list';
          selectedReq = 0;
          scrollOffset = 0;
          searchTerm = '';
          render();
        } else if (k == 50) {
          // 2 - Environments
          currentView = 'envs';
          render();
        } else if (k == 51) {
          // 3 - Quick Run
          currentView = 'quickrun';
          quickRunUrl = '';
          quickRunMethod = 'GET';
          render();
        }
      } else if (currentView == 'list') {
        if (keyBytes.length == 3 && keyBytes[0] == 27 && keyBytes[1] == 91) {
          if (keyBytes[2] == 65) {
            // Up
            if (selectedReq > 0) selectedReq--;
            render();
          } else if (keyBytes[2] == 66) {
            // Down
            selectedReq++;
            render();
          }
        } else if (keyBytes.length == 1) {
          int k = keyBytes[0];
          if (k == 27) {
            // ESC
            currentView = 'menu';
            render();
          } else if (k == 47) {
            // /
            currentView = 'search';
            render();
          } else if (k == 13 || k == 10) {
            // ENTER
            // Run selected
            final results = <Map<String, dynamic>>[];
            for (final r in reqs) {
              final n = r['name']?.toString().toLowerCase() ?? '';
              final u = r['url']?.toString().toLowerCase() ?? '';
              if (searchTerm.isEmpty ||
                  n.contains(searchTerm.toLowerCase()) ||
                  u.contains(searchTerm.toLowerCase())) {
                results.add(r);
              }
            }
            if (results.isNotEmpty && selectedReq < results.length) {
              final req = results[selectedReq];
              lastRequestMethod =
                  req['method']?.toString().toUpperCase() ?? 'GET';
              lastRequestUrl = req['url']?.toString() ?? '';
              stdout.write('\x1B[2J\x1B[3J\x1B[H');
              print("\n  🚀 Running ${req['name']}...");
              final ctx = HttpRequestContext(
                method: req['method']?.toString() ?? 'GET',
                url: req['url']?.toString() ?? '',
                headers: (req['headers'] as Map?)?.cast<String, String>(),
                body: req['body']?.toString(),
                timeoutMs: 30000,
              );
              lastResult = await executeHttpRequest(ctx);

              final data = lastResult!['data'] as Map<String, dynamic>? ?? {};
              final lowerHeaders = (data['headers'] as Map? ?? {}).map(
                (k, v) => MapEntry(k.toString().toLowerCase(), v.toString()),
              );
              String bodyStr = data['body']?.toString() ?? '';
              try {
                final decoded = jsonDecode(bodyStr);
                bodyStr = JsonEncoder.withIndent('  ').convert(decoded);
              } catch (_) {}
              responseLines = bodyStr.split('\n');

              int width = stdout.terminalColumns;
              for (int i = 0; i < responseLines.length; i++) {
                responseLines[i] = truncate(responseLines[i], width - 6);
              }
              responseScrollOffset = 0;
              quickRunUrl = ''; // Clear quick run so esc goes to list
              currentView = 'response';
              render();
            }
          } else if (k == 106) {
            // j / down
            selectedReq++;
            render();
          } else if (k == 107) {
            // k / up
            if (selectedReq > 0) selectedReq--;
            render();
          }
        }
      } else if (currentView == 'envs') {
        if (keyBytes.length == 1 && keyBytes[0] == 27) {
          // ESC
          currentView = 'menu';
          render();
        }
      } else if (currentView == 'quickrun') {
        if (keyBytes.length == 1) {
          int k = keyBytes[0];
          if (k == 27) {
            // ESC
            quickRunUrl = '';
            currentView = 'menu';
            render();
          } else if (k == 9) {
            // TAB
            const methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];
            final idx = methods.indexOf(quickRunMethod);
            quickRunMethod = methods[(idx + 1) % methods.length];
            render();
          } else if (k == 13 || k == 10) {
            // ENTER
            if (quickRunUrl.isNotEmpty) {
              lastRequestMethod = quickRunMethod;
              lastRequestUrl = quickRunUrl;
              stdout.write('\x1B[2J\x1B[3J\x1B[H');
              stdout.write('  🚀 Running $quickRunMethod $quickRunUrl...\n');
              final ctx = HttpRequestContext(
                method: quickRunMethod,
                url: quickRunUrl,
                timeoutMs: 30000,
              );
              lastResult = await executeHttpRequest(ctx);

              final data = lastResult!['data'] as Map<String, dynamic>? ?? {};
              final lowerHeaders = (data['headers'] as Map? ?? {}).map(
                (k, v) => MapEntry(k.toString().toLowerCase(), v.toString()),
              );
              String bodyStr = data['body']?.toString() ?? '';
              try {
                final decoded = jsonDecode(bodyStr);
                bodyStr = JsonEncoder.withIndent('  ').convert(decoded);
              } catch (_) {}
              responseLines = bodyStr.split('\n');

              int width = stdout.terminalColumns;
              for (int i = 0; i < responseLines.length; i++) {
                responseLines[i] = truncate(responseLines[i], width - 6);
              }
              responseScrollOffset = 0;
              currentView = 'response';
              render();
            }
          } else if (k == 127 || k == 8) {
            // Backspace
            if (quickRunUrl.isNotEmpty) {
              quickRunUrl = quickRunUrl.substring(0, quickRunUrl.length - 1);
              render();
            }
          } else if (k >= 32 && k < 127) {
            // Printable chars
            quickRunUrl += String.fromCharCode(k);
            render();
          }
        }
      } else if (currentView == 'search') {
        if (keyBytes.length == 1) {
          int k = keyBytes[0];
          if (k == 27) {
            // ESC
            searchTerm = '';
            currentView = 'list';
            render();
          } else if (k == 13 || k == 10) {
            // ENTER
            currentView = 'list';
            render();
          } else if (k == 127 || k == 8) {
            // Backspace
            if (searchTerm.isNotEmpty) {
              searchTerm = searchTerm.substring(0, searchTerm.length - 1);
              selectedReq = 0;
              render();
            }
          } else if (k >= 32 && k <= 126) {
            searchTerm += String.fromCharCode(k);
            selectedReq = 0;
            render();
          }
        } else if (keyBytes.length == 3 &&
            keyBytes[0] == 27 &&
            keyBytes[1] == 91) {
          if (keyBytes[2] == 65) {
            // Up
            if (selectedReq > 0) selectedReq--;
            render();
          } else if (keyBytes[2] == 66) {
            // Down
            selectedReq++;
            render();
          }
        }
      }
    }
  } finally {
    stdin.echoMode = true;
    stdin.lineMode = true;
    stdout.write('\x1B[?25h'); // Show cursor
    stdout.write('\x1B[2J\x1B[3J\x1B[H'); // Clear
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Menu-driven interactive TUI  (launched when `apidash` is run with no args)
// ─────────────────────────────────────────────────────────────────────────────

// ── Alternate-screen / kiosk helpers ─────────────────────────────────────────

void _enterAltScreen() {
  stdout.write('\x1B[?1049h'); // enter alternate screen — no scrollback
  stdout.write('\x1B[?25l'); // hide cursor
}

void _leaveAltScreen() {
  stdout.write('\x1B[?25h'); // restore cursor
  stdout.write('\x1B[?1049l'); // leave alternate screen
  _stopStdinListening();
}

// ── Input helpers ─────────────────────────────────────────────────────────────

Future<void> _pressEnter() async {
  stdout.write('\n  $gray[Press Enter to continue...]$reset');
  while (true) {
    if (await _readKey() == 'enter') break;
  }
}

/// Read ONE key in raw mode.  Returns 'esc', 'enter', 'backspace',
/// a lowercase printable character, or '' for anything else.
/// Read ONE key asynchronously in raw mode.
/// Real ESC = [27] alone. Escape sequences (arrows, mouse scroll) = [27, 91, ...]
/// Using stdin.listen() delivers full multi-byte sequences in one chunk,
/// so mouse-scroll/arrow keys cannot be mis-read as ESC.
// ── Single global stdin reader ─────────────────────────────────────────────
final _keyController = StreamController<List<int>>.broadcast();
StreamSubscription<List<int>>? _stdinSub;
bool _stdinListening = false;

void _ensureStdinListening() {
  if (_stdinListening) return;
  _stdinListening = true;
  try {
    stdin.echoMode = false;
    stdin.lineMode = false;
  } catch (_) {}
  if (_stdinSub == null) {
    _stdinSub = stdin.listen(
      (bytes) => _keyController.add(bytes),
      onError: (_) {},
      onDone: () {},
      cancelOnError: false,
    );
  } else {
    _stdinSub?.resume();
  }
}

void _stopStdinListening() {
  if (!_stdinListening) return;
  _stdinListening = false;
  _stdinSub?.pause();
  try {
    stdin.echoMode = true;
    stdin.lineMode = true;
  } catch (_) {}
}

Future<String> _readKey() async {
  _ensureStdinListening();
  try {
    stdin.echoMode = false;
    stdin.lineMode = false;
  } catch (_) {}

  final bytes = await _keyController.stream.first;

  if (bytes.isEmpty) return '';
  final b = bytes[0];
  if (b == 27) {
    if (bytes.length == 1) return 'esc';
    // Arrow/navigation keys: ESC [ A/B/C/D
    if (bytes.length == 3 && bytes[1] == 91) {
      if (bytes[2] == 65) return 'up';
      if (bytes[2] == 66) return 'down';
      if (bytes[2] == 67) return 'right';
      if (bytes[2] == 68) return 'left';
    }
    return ''; // other escape sequence — ignored by callers
  }
  if (b == 13 || b == 10) return 'enter';
  if (b == 127 || b == 8) return 'backspace';
  if (b >= 32 && b < 127) return String.fromCharCode(b).toLowerCase();
  return '';
}

// Keys helpers simplified

/// Styled line-mode text input.  Returns null on blank input (= go back).
Future<String?> _readLine(String label, {bool isUrl = false}) async {
  print('  $cyan\u250c\u2500 $yellow$label $gray(blank = back)$reset');
  stdout.write('  $cyan\u2514\u25ba$reset $green');
  stdout.write('\x1B[?25h'); // Show cursor during input

  try {
    stdin.echoMode = false;
    stdin.lineMode = false;
  } catch (_) {}

  final buffer = StringBuffer();

  while (true) {
    final bytes = await _keyController.stream.first;
    if (bytes.isEmpty) continue;
    final b = bytes[0];

    if (b == 13 || b == 10) {
      stdout.write('\n$reset');
      break;
    } else if (b == 27) {
      // Ignore ALL escape sequences (single ESC or multi-byte arrow/focus/resize
      // sequences). GNOME Terminal in alt-screen sends spurious lone ESC bytes
      // on resize / focus-in events — treating them as "cancel" causes the
      // URL input to silently abort mid-typing.
      // Cancellation is via Enter on an empty buffer (see prompt hint).
      continue;
    } else if (b == 127 || b == 8) {
      if (buffer.isNotEmpty) {
        final s = buffer.toString();
        buffer.clear();
        buffer.write(s.substring(0, s.length - 1));
        stdout.write('\x1B[1D\x1B[K');
      }
    } else if (b >= 32 && b < 127) {
      for (var byte in bytes) {
        if (byte >= 32 && byte < 127) {
          final ch = String.fromCharCode(byte);
          buffer.write(ch);
          stdout.write(ch);
        }
      }
    }
    // Ignore arrow keys and other multi-byte sequences (b==27 with more bytes)
  }

  stdout.write('\x1B[?25l'); // Hide cursor again after input
  String val = buffer.toString().trim();
  if (val.isEmpty) return null;
  if (isUrl && !val.startsWith('http://') && !val.startsWith('https://')) {
    val = 'https://' + val;
    print('  $gray(auto-added https:// prefix)$reset');
  }
  return val;
}

// ── Command runners ───────────────────────────────────────────────────────────

Future<void> _runApidash(List<String> apidashArgs) async {
  _leaveAltScreen();
  stdout.write('\x1B[2J\x1B[H');
  final cmd = 'apidash ${apidashArgs.join(' ')}';
  print('  $cyan\$ $cmd$reset\n');
  final r = await Process.run('apidash', apidashArgs, runInShell: true);
  List<String> outLines = r.stdout.toString().split('\n');
  if (outLines.isNotEmpty && outLines.last.isEmpty) outLines.removeLast();
  if (r.stderr.toString().trim().isNotEmpty) {
    outLines.add('$red${r.stderr.toString().trim()}$reset');
  }
  final wasQuit = await _paginateLines(outLines);

  if (!wasQuit && outLines.length < stdout.terminalLines) {
    await _pressEnter();
  }
  
  _enterAltScreen();
}

Future<void> _runShell(String cmd) async {
  _leaveAltScreen();
  stdout.write('\x1B[2J\x1B[H');
  print('\n  $cyan\$ $cmd$reset\n');
  final r = await Process.run(cmd, [], runInShell: true);
  if (r.stdout.toString().isNotEmpty) stdout.write(r.stdout);
  if (r.stderr.toString().isNotEmpty) stdout.write('$red${r.stderr}$reset');
  await _pressEnter();
  _enterAltScreen();
}

Future<void> _mcpCommand(String displayCmd, String shCmd) async {
  stdout.write('\x1B[2J\x1B[H');
  printApidashLogo();
  print('');
  print('  $bold$yellow  MCP Command$reset\n');
  print('  $cyan\$ $displayCmd$reset\n');
  stdout.write('\n  ${green}Run this? [y/n]: $reset');
  final ans = await _readKey();
  stdout.write('${yellow}$ans$reset\n');

  if (ans == 'y') {
    _leaveAltScreen();
    stdout.write('\x1B[2J\x1B[H');
    print('\n  $cyan\$ $displayCmd$reset\n');
    final r = await Process.run(shCmd, [], runInShell: true);
    if (r.stdout.toString().isNotEmpty) stdout.write(r.stdout);
    if (r.stderr.toString().isNotEmpty) stdout.write('$red${r.stderr}$reset');
    await _pressEnter();
    _enterAltScreen();
  } else {
    print('\n  ${gray}Skipped.$reset');
    await _pressEnter();
  }
}

// ── HTTP Requests submenu ─────────────────────────────────────────────────────

Future<void> _menuHttp() async {
  while (true) {
    stdout.write('\x1B[2J\x1B[H');
    printApidashLogo();
    print('');
    print('  $bold$yellow HTTP Requests$reset\n');
    print('  ${yellow}[1]$reset Run a new ${green}GET$reset request');
    print('  ${yellow}[2]$reset Run a new ${yellow}POST$reset request');
    print('  ${yellow}[3]$reset Run a new ${blue}PUT$reset request');
    print('  ${yellow}[4]$reset Run a new ${red}DELETE$reset request');
    print('  ${yellow}[5]$reset List all saved requests');
    print('  ${yellow}[6]$reset Filter saved requests by method');
    print('  ${yellow}[7]$reset Send saved request by ID');
    print('  ${yellow}[8]$reset Send saved request by name');
    print('  ${yellow}[b / ESC]$reset Back\n');
    print('  $gray[1-8 / ESC=back]$reset');
    stdout.write('  ${green}Select > $reset');
    final choice = await _readKey();

    if (choice == 'esc')
      stdout.write('${yellow}ESC$reset\n');
    else if (choice.isNotEmpty)
      stdout.write('${yellow}$choice$reset\n');

    if (choice == 'esc') return;

    switch (choice) {
      case '1':
        stdout.write('\x1B[2J\x1B[H');
        print('  $bold$green GET Request$reset\n');
        final url = await _readLine('URL', isUrl: true);
        if (url == null) break;
        await _runApidash(['run', '--url', url, '--method', 'GET']);
        break;
      case '2':
        stdout.write('\x1B[2J\x1B[H');
        print('  $bold$yellow POST Request$reset\n');
        final url = await _readLine('URL', isUrl: true);
        if (url == null) break;
        final body = await _readLine('Body JSON (blank = {})') ?? '{}';
        await _runApidash([
          'run',
          '--url',
          url,
          '--method',
          'POST',
          '--body',
          body,
          '--header',
          'Content-Type: application/json',
        ]);
        break;
      case '3':
        stdout.write('\x1B[2J\x1B[H');
        print('  $bold$blue PUT Request$reset\n');
        final url = await _readLine('URL', isUrl: true);
        if (url == null) break;
        final body = await _readLine('Body JSON (blank = {})') ?? '{}';
        await _runApidash([
          'run',
          '--url',
          url,
          '--method',
          'PUT',
          '--body',
          body,
        ]);
        break;
      case '4':
        stdout.write('\x1B[2J\x1B[H');
        print('  $bold$red DELETE Request$reset\n');
        final url = await _readLine('URL', isUrl: true);
        if (url == null) break;
        await _runApidash(['run', '--url', url, '--method', 'DELETE']);
        break;
      case '5':
        final selectedId = await handleList([], isStandalone: false);
        if (selectedId != null) {
          await _runApidash(['send', '--id', selectedId]);
        }
        break;
      case '6':
        stdout.write('\x1B[2J\x1B[H');
        print('  $bold Filter by Method$reset\n');
        final method = await _readLine('Method (GET/POST/PUT/DELETE/PATCH)');
        if (method == null) break;
        await _runApidash(['list', '--filter', method.toUpperCase()]);
        break;
      case '7':
        stdout.write('\x1B[2J\x1B[H');
        print('  $bold Send by ID$reset\n');
        final id = await _readLine('Request ID');
        if (id == null) break;
        await _runApidash(['send', '--id', id]);
        break;
      case '8':
        stdout.write('\x1B[2J\x1B[H');
        print('  $bold Send by Name$reset\n');
        final name = await _readLine('Request Name');
        if (name == null) break;
        await _runApidash(['send', '--name', name]);
        break;
      default:
        break;
    }
  }
}

// ── GraphQL submenu ───────────────────────────────────────────────────────────

Future<void> _menuGraphQL() async {
  while (true) {
    stdout.write('\x1B[2J\x1B[H');
    printApidashLogo();
    print('');
    print('  $bold$cyan GraphQL$reset\n');
    print('  ${yellow}[1]$reset Explore a GraphQL schema');
    print('  ${yellow}[2]$reset Execute a GraphQL query');
    print('  ${yellow}[3]$reset Send saved GraphQL request');
    print('  ${yellow}[b / ESC]$reset Back\n');
    print('  $gray[1-3 / b=back / ESC=back]$reset');
    stdout.write('  ${green}Select > $reset');
    final choice = await _readKey();

    if (choice == 'esc')
      stdout.write('${yellow}ESC$reset\n');
    else if (choice.isNotEmpty)
      stdout.write('${yellow}$choice$reset\n');

    if (choice == 'esc') return;

    switch (choice) {
      case '1':
        stdout.write('\x1B[2J\x1B[H');
        print('  $bold$cyan Schema Introspection$reset\n');
        final url = await _readLine('GraphQL Endpoint URL');
        if (url == null) break;
        final body = jsonEncode({'query': '{ __schema { types { name } } }'});
        await _runApidash([
          'run',
          '--url',
          url,
          '--method',
          'POST',
          '--header',
          'Content-Type: application/json',
          '--body',
          body,
        ]);
        break;
      case '2':
        stdout.write('\x1B[2J\x1B[H');
        print('  $bold$cyan Execute Query$reset\n');
        final url = await _readLine('GraphQL Endpoint URL');
        if (url == null) break;
        final query = await _readLine('GraphQL Query (single line)');
        if (query == null) break;
        final gqlBody = jsonEncode({
          'query': query,
          'variables': <String, dynamic>{},
        });
        await _runApidash([
          'run',
          '--url',
          url,
          '--method',
          'POST',
          '--header',
          'Content-Type: application/json',
          '--body',
          gqlBody,
        ]);
        break;
      case '3':
        stdout.write('\x1B[2J\x1B[H');
        print('  ${gray}Loading workspace...$reset\n');
        await loadHiveIntoWorkspace();
        final allReqs = WorkspaceState().requests;
        final gqlReqs = allReqs.where((r) {
          final name = r['name']?.toString().toLowerCase() ?? '';
          final body = r['body']?.toString() ?? '';
          return name.contains('graphql') ||
              body.contains('__schema') ||
              body.contains('"query"');
        }).toList();
        if (gqlReqs.isEmpty) {
          print('  ${yellow}No saved GraphQL requests found.$reset');
          await _pressEnter();
          break;
        }
        printBeautifulList(gqlReqs);
        print('');
        final numStr = await _readLine('Select request number (0 = cancel)');
        if (numStr == null) break;
        final num = int.tryParse(numStr) ?? 0;
        if (num < 1 || num > gqlReqs.length) {
          print('  ${gray}Cancelled.$reset');
          await _pressEnter();
          break;
        }
        final theId = gqlReqs[num - 1]['id']?.toString() ?? '';
        if (theId.isEmpty) {
          print('  ${red}Request has no ID.$reset');
          await _pressEnter();
          break;
        }
        await _runApidash(['send', '--id', theId]);
        break;
      default:
        break;
    }
  }
}

// ── Workspace submenu ─────────────────────────────────────────────────────────

Future<void> _menuWorkspace() async {
  while (true) {
    stdout.write('\x1B[2J\x1B[H');
    printApidashLogo();
    print('');
    print('  $bold$magenta Workspace$reset\n');
    print('  ${yellow}[1]$reset List all requests');
    print('  ${yellow}[2]$reset List GET requests');
    print('  ${yellow}[3]$reset List POST requests');
    print('  ${yellow}[4]$reset List all environments');
    print('  ${yellow}[5]$reset Send request by ID');
    print('  ${yellow}[6]$reset Send request by name');
    print('  ${yellow}[7]$reset View raw workspace JSON');
    print('  ${yellow}[b / ESC]$reset Back\n');
    print('  $gray[1-7 / b=back / ESC=back]$reset');
    stdout.write('  ${green}Select > $reset');
    final choice = await _readKey();

    if (choice == 'esc')
      stdout.write('${yellow}ESC$reset\n');
    else if (choice.isNotEmpty)
      stdout.write('${yellow}$choice$reset\n');

    if (choice == 'esc') return;

    switch (choice) {
      case '1':
        final selectedId = await handleList([], isStandalone: false);
        if (selectedId != null) {
          await _runApidash(['send', '--id', selectedId]);
        }
        break;
      case '2':
        await _runApidash(['list', '--filter', 'GET']);
        break;
      case '3':
        await _runApidash(['list', '--filter', 'POST']);
        break;
      case '4':
        await _runApidash(['envs']);
        break;
      case '5':
        stdout.write('\x1B[2J\x1B[H');
        print('  $bold Send by ID$reset\n');
        final id = await _readLine('Request ID');
        if (id == null) break;
        await _runApidash(['send', '--id', id]);
        break;
      case '6':
        stdout.write('\x1B[2J\x1B[H');
        print('  $bold Send by Name$reset\n');
        final name = await _readLine('Request Name');
        if (name == null) break;
        await _runApidash(['send', '--name', name]);
        break;
      case '7':
        await _runApidash(['list', '--json']);
        break;
      default:
        break;
    }
  }
}

// ── MCP Server submenu ────────────────────────────────────────────────────────

Future<void> _menuMCP() async {
  while (true) {
    stdout.write('\x1B[2J\x1B[H');
    printApidashLogo();
    print('');
    print('  $bold$blue MCP Server$reset\n');
    print('  ${yellow}[1]$reset Start server  ${gray}(HTTP :8000)$reset');
    print('  ${yellow}[2]$reset Start on custom port');
    print('  ${yellow}[3]$reset SSE mode');
    print('  ${yellow}[4]$reset Stdio mode');
    print('  ${yellow}[5]$reset With OAuth 2.1');
    print('  ${yellow}[6]$reset With static token');
    print('  ${yellow}[7]$reset Health check');
    print('  ${yellow}[b / ESC]$reset Back\n');
    print('  $gray[1-7 / b=back / ESC=back]$reset');
    stdout.write('  ${green}Select > $reset');
    final choice = await _readKey();

    if (choice == 'esc')
      stdout.write('${yellow}ESC$reset\n');
    else if (choice.isNotEmpty)
      stdout.write('${yellow}$choice$reset\n');

    if (choice == 'esc') return;

    switch (choice) {
      case '1':
        await _mcpCommand(
          'dart run bin/apidash_mcp.dart',
          'dart run bin/apidash_mcp.dart',
        );
        break;
      case '2':
        stdout.write('\x1B[2J\x1B[H');
        print('  $bold$blue MCP \u2014 Custom Port$reset\n');
        final port = await _readLine('Port number');
        if (port == null) break;
        await _mcpCommand(
          'dart run bin/apidash_mcp.dart --port $port',
          'dart run bin/apidash_mcp.dart --port $port',
        );
        break;
      case '3':
        await _mcpCommand(
          'dart run bin/apidash_mcp.dart --sse',
          'dart run bin/apidash_mcp.dart --sse',
        );
        break;
      case '4':
        await _mcpCommand(
          'dart run bin/apidash_mcp.dart --stdio',
          'dart run bin/apidash_mcp.dart --stdio',
        );
        break;
      case '5':
        await _mcpCommand(
          'APIDASH_MCP_AUTH=true dart run bin/apidash_mcp.dart',
          'APIDASH_MCP_AUTH=true dart run bin/apidash_mcp.dart',
        );
        break;
      case '6':
        stdout.write('\x1B[2J\x1B[H');
        print('  $bold$blue MCP \u2014 Static Token$reset\n');
        final token = await _readLine('Token value');
        if (token == null) break;
        await _mcpCommand(
          'APIDASH_MCP_TOKEN=$token dart run bin/apidash_mcp.dart',
          'APIDASH_MCP_TOKEN=$token dart run bin/apidash_mcp.dart',
        );
        break;
      case '7':
        await _runShell('curl -s http://localhost:8000/health');
        break;
      default:
        break;
    }
  }
}

// ── Quick Commands cheatsheet ─────────────────────────────────────────────────

Future<void> _showQuickCommands() async {
  stdout.write('\x1B[2J\x1B[H');
  printApidashLogo();
  print('');
  print('  $bold$yellow Quick Commands Cheatsheet$reset\n');

  print('  $bold$cyan HTTP Requests$reset');
  print(r"  $ apidash run --url https://httpbin.org/get --method GET");
  print('  $gray  \u2192 Run a GET request$reset\n');

  print('  $bold$cyan Saved Requests$reset');
  print(r"  $ apidash list                        " + '$gray\u2192 All$reset');
  print(
    r"  $ apidash list --filter GET           " +
        '$gray\u2192 Filter by method$reset',
  );
  print(
    r"  $ apidash list --json                 " + '$gray\u2192 Raw JSON$reset',
  );
  print(
    r"  $ apidash send --id <id>              " +
        '$gray\u2192 Send by ID$reset',
  );
  print(
    r'  $ apidash send --name "Get Users"     ' +
        '$gray\u2192 Send by name$reset\n',
  );

  print('  $bold$cyan Environments$reset');
  print(
    r"  $ apidash envs                        " + '$gray\u2192 List envs$reset',
  );
  print(
    r"  $ apidash envs --json                 " +
        '$gray\u2192 JSON output$reset\n',
  );

  print('  $bold$cyan GraphQL$reset');
  print(r'  $ apidash run --url <gql> --method POST \');
  print(r'       --header "Content-Type: application/json" \');
  print(
    r'       --body ' +
        "'" +
        r'{"query":"{ __schema { types { name } } }"}' +
        "'",
  );
  print('  $gray  \u2192 Schema introspection$reset\n');

  print('  $bold$cyan MCP Server$reset');
  print(
    r"  $ dart run bin/apidash_mcp.dart       " +
        '$gray\u2192 HTTP :8000$reset',
  );
  print(
    r"  $ dart run bin/apidash_mcp.dart --sse " + '$gray\u2192 SSE mode$reset',
  );
  print(
    r"  $ curl http://localhost:8000/health    " +
        '$gray\u2192 Health check$reset\n',
  );

  print('  $bold$cyan TUI Modes$reset');
  print(r"  $ apidash             " + '$gray\u2192 This menu TUI$reset');
  print(r"  $ apidash interactive " + '$gray\u2192 Arrow-key TUI$reset\n');
  stdout.write('\n  $gray[Press Enter to continue...]$reset');
  while (true) {
    if (await _readKey() == 'enter') break;
  }
}

// ── Main interactive entry point ──────────────────────────────────────────────

Future<void> _runInteractive() async {
  if (!stdout.hasTerminal) {
    print('${red}Interactive mode requires a terminal.$reset');
    exit(1);
  }

  _ensureStdinListening();

  StreamSubscription? sigintSub;
  try {
    sigintSub = ProcessSignal.sigint.watch().listen((_) {
      _leaveAltScreen();
      print('\n${green}  Goodbye! \u{1F44B}$reset\n');
      exit(0);
    });
  } catch (_) {}

  _enterAltScreen();

  try {
    while (true) {
      stdout.write('\x1B[2J\x1B[H');
      printApidashLogo();
      print('');
      print('  $bold$yellow Main Menu$reset\n');
      print('  ${yellow}[1]$reset HTTP Requests');
      print('  ${yellow}[2]$reset GraphQL');
      print('  ${yellow}[3]$reset Workspace');
      print('  ${yellow}[4]$reset MCP Server');
      print('  ${yellow}[5]$reset Quick Commands ${gray}(cheatsheet)$reset');
      print('  ${yellow}[ESC]$reset Quit\n');
      print('  $gray[1-5 / ESC=quit]$reset');
      stdout.write('  ${green}Select > $reset');

      final choice = await _readKey();

      if (choice == 'esc') {
        stdout.write('${yellow}ESC$reset\n');
      } else if (choice.isNotEmpty) {
        stdout.write('${yellow}$choice$reset\n');
      }

      switch (choice) {
        case '1':
          await _menuHttp();
          break;
        case '2':
          await _menuGraphQL();
          break;
        case '3':
          await _menuWorkspace();
          break;
        case '4':
          await _menuMCP();
          break;
        case '5':
          await _showQuickCommands();
          break;
        case 'esc':
          _leaveAltScreen();
          print('${green}  Goodbye! \u{1F44B}$reset\n');
          exit(0);
        default:
          break;
      }
    }
  } finally {
    _leaveAltScreen();
  }
}

void main(List<String> args) async {
  if (args.isEmpty) {
    await _runInteractive();
    return;
  }
  if (args.contains('--help') && args.length == 1) {
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

  // Hard exit to close event loops/listeners since we're done
  exit(0);
}
