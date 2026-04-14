import sys

with open('bin/apidash_cli.dart', 'r') as f:
    orig = f.read()

target_start = "Future<void> runInteractive() async {"
target_end = "void main(List<String> args) async {"

start_idx = orig.find(target_start)
end_idx = orig.find(target_end)

if start_idx == -1 or end_idx == -1:
    print("Could not find boundaries")
    sys.exit(1)

new_run_interactive = r'''Future<void> runInteractive() async {
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
      stdout.write('\x1B[2J\x1B[H');
      int height = stdout.terminalLines;
      int width = stdout.terminalColumns;
      
      if (currentView == 'menu') {
        print("""  ╔═══════════════════════════════════════╗
  ║         🚀 $bold APIDash CLI v0.5.0$reset          ║
  ║   API Testing from your Terminal      ║
  ╚═══════════════════════════════════════╝

  [1] Browse & Run Requests
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
          final reqModel = data['requestModel'] as Map? ?? {};
          final method = reqModel['method']?.toString().toUpperCase() ?? 'GET';
          final url = reqModel['url']?.toString() ?? '';
          
          final emoji = success ? '✅' : '❌';
          String colorStatus = red;
          if (status >= 200 && status < 300) colorStatus = green;
          else if (status >= 400 && status < 500) colorStatus = yellow;

          print('┌─ Response ${"─" * (width - 13)}┐');
          print('│  $emoji $colorStatus$status OK$reset · ${duration}ms' + ' ' * (width - 18 - status.toString().length - duration.toString().length) + '│');
          print('│  $bold$method$reset ${truncate(url, width - method.length - 8).padRight(width - method.length - 8)} │');
          print('├─ Headers ${"─" * (width - 12)}┤');

          final rawHeaders = data['headers'] as Map? ?? {};
          final lowerHeaders = rawHeaders.map((k, v) => MapEntry(k.toString().toLowerCase(), v.toString()));
          final importantKeys = ['content-type', 'content-length', 'server', 'x-ratelimit-remaining', 'x-request-id', 'authorization', 'cache-control', 'location'];
          
          bool hasNotable = false;
          for (final k in importantKeys) {
            if (lowerHeaders.containsKey(k)) {
               hasNotable = true;
               String val = lowerHeaders[k]!;
               String line = '  $cyan$k$reset: $val';
               print('│' + line + " " * (width - k.length - val.length - 6) + ' │');
            }
          }
          if (!hasNotable) {
            print('│  (no notable headers)' + " " * (width - 24) + ' │');
          }

          int bodyHeight = height - 9; // borders + headers max area approx
          if (bodyHeight < 5) bodyHeight = 5;
          String bodyIndicator = 'Body (Line ${responseScrollOffset + 1}-${math.min(responseLines.length, responseScrollOffset + bodyHeight)} of ${responseLines.length})';
          print('├─ $bodyIndicator ${"─" * math.max(0, width - bodyIndicator.length - 6)}┤');

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
           if (searchTerm.isEmpty || n.contains(searchTerm.toLowerCase()) || u.contains(searchTerm.toLowerCase()) || m.contains(searchTerm.toLowerCase())) {
              results.add(r);
           }
        }
        
        if (selectedReq >= results.length) selectedReq = math.max(0, results.length - 1);
        
        int listHeight = math.max(1, height - 7); // updated height alloc
        if (scrollOffset > selectedReq) scrollOffset = selectedReq;
        if (selectedReq >= scrollOffset + listHeight) scrollOffset = selectedReq - listHeight + 1;
        if (scrollOffset > math.max(0, results.length - listHeight)) scrollOffset = math.max(0, results.length - listHeight);
        
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
                 nPad = nPad.substring(0, idx) + '\x1B[43m\x1B[31m' + nPad.substring(idx, idx+s.length) + reset + nPad.substring(idx+s.length);
              }
              if (uPad.toLowerCase().contains(s)) {
                 int idx = uPad.toLowerCase().indexOf(s);
                 uPad = uPad.substring(0, idx) + '\x1B[43m\x1B[31m' + uPad.substring(idx, idx+s.length) + reset + uPad.substring(idx+s.length);
              }
           }
           
           if (i == selectedReq) {
              stdout.write('▶ \x1B[1m${colorMethod(mPad)}\x1B[1m $nPad $rawU\x1B[0m\n');
           } else {
              stdout.write('  ${colorMethod(mPad)} $nPad ${gray}$uPad$reset\n');
           }
        }
        
        // Scroll indicators
        if (results.length > listHeight) {
          String ind = "  " + (scrollOffset > 0 ? "↑ more  " : "") + " " + (endIdx < results.length ? "↓ more (${results.length - endIdx} remaining)" : "");
          stdout.write('\x1B[${height - 1}H' + ind);
        }
        
        stdout.write('\x1B[${height}H'); 
        if (currentView == 'search') {
          stdout.write('  [ESC] Clear/Exit search   [ENTER] Select   Type to filter...');
        } else {
          stdout.write('  [↑/↓] Navigate  [ENTER] Run  [/] Search  [ESC] Menu');
        }
      } else if (currentView == 'envs') {
        final wsFile = File('${Platform.environment['HOME']}/.local/share/apidash/apidash_mcp_workspace.json');
        List envs = [];
        if (wsFile.existsSync()) {
          try {
            final ws = jsonDecode(wsFile.readAsStringSync());
            envs = ws['environments'] as List? ?? [];
          } catch(_) {}
        }
        if (envs.isEmpty) envs = WorkspaceState().environments;
        
        stdout.write('  🌍 \x1B[1mEnvironments (${envs.length})\x1B[0m\n\n');
        if (envs.isEmpty) {
          stdout.write('  No environments found.\n');
          stdout.write('  \x1B[90mCreate environments in the APIDash GUI first.\x1B[0m\n');
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
              stdout.write('    \x1B[33m$key\x1B[0m = \x1B[32m$val\x1B[0m$dim\n');
            }
            stdout.write('\n');
          }
        }
        stdout.write('\x1B[${height}H');
        stdout.write('  [ESC] Back to menu');

      } else if (currentView == 'quickrun') {
        stdout.write('  ⚡ \x1B[1mQuick Run\x1B[0m\n\n');
        stdout.write('  Method : [\x1B[1m$quickRunMethod\x1B[0m] ← press G/P/U/D to change\n');
        stdout.write('  URL    : \x1B[1m\x1B[36m${quickRunUrl}_\x1B[0m\n\n');
        stdout.write('  \x1B[90mExamples:\x1B[0m\n');
        stdout.write('  \x1B[90m  https://httpbin.org/get\x1B[0m\n');
        stdout.write('  \x1B[90m  https://api.github.com/users/octocat\x1B[0m\n\n');
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
             if (keyBytes[2] == 65) { // Up
                if (responseScrollOffset > 0) responseScrollOffset--;
                render();
             } else if (keyBytes[2] == 66) { // Down
                if (responseScrollOffset < responseLines.length - bodyHeight) responseScrollOffset++;
                render();
             }
          } else if (keyBytes.length == 1 && keyBytes[0] == 27) { // ESC
             if (quickRunUrl.isNotEmpty) currentView = 'quickrun';
             else currentView = 'list';
             render();
          }
          continue;
       }
       
       if (currentView == 'menu') {
          int k = keyBytes[0];
          if (k == 113 || k == 81 || k == 27) { // q or Q or ESC
             break;
          } else if (k == 49) { // 1 - Browse Requests
             currentView = 'list';
             selectedReq = 0;
             scrollOffset = 0;
             searchTerm = '';
             render();
          } else if (k == 50) { // 2 - Environments
             currentView = 'envs';
             render();
          } else if (k == 51) { // 3 - Quick Run
             currentView = 'quickrun';
             quickRunUrl = '';
             quickRunMethod = 'GET';
             render();
          }
       } else if (currentView == 'list') {
          if (keyBytes.length == 3 && keyBytes[0] == 27 && keyBytes[1] == 91) {
             if (keyBytes[2] == 65) { // Up
                if (selectedReq > 0) selectedReq--;
                render();
             } else if (keyBytes[2] == 66) { // Down
                selectedReq++;
                render();
             }
          } else if (keyBytes.length == 1) {
             int k = keyBytes[0];
             if (k == 27) { // ESC
                currentView = 'menu';
                render();
             } else if (k == 47) { // /
                currentView = 'search';
                render();
             } else if (k == 13 || k == 10) { // ENTER
                // Run selected
                final results = <Map<String, dynamic>>[];
                for (final r in reqs) {
                   final n = r['name']?.toString().toLowerCase() ?? '';
                   final u = r['url']?.toString().toLowerCase() ?? '';
                   if (searchTerm.isEmpty || n.contains(searchTerm.toLowerCase()) || u.contains(searchTerm.toLowerCase())) {
                      results.add(r);
                   }
                }
                if (results.isNotEmpty && selectedReq < results.length) {
                   final req = results[selectedReq];
                   stdout.write('\x1B[2J\x1B[H');
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
                   final lowerHeaders = (data['headers'] as Map? ?? {}).map((k, v) => MapEntry(k.toString().toLowerCase(), v.toString()));
                   String bodyStr = data['body']?.toString() ?? '';
                   if ((lowerHeaders['content-type'] ?? '').contains('text/html')) {
                      responseLines = [
                        '[HTML Response — use a browser to view this URL]',
                        'Tip: Try a JSON API endpoint instead, e.g. https://httpbin.org/get'
                      ];
                   } else {
                      try {
                        final decoded = jsonDecode(bodyStr);
                        bodyStr = JsonEncoder.withIndent('  ').convert(decoded);
                      } catch (_) {}
                      responseLines = bodyStr.split('\n');
                   }
                   
                   int width = stdout.terminalColumns;
                   for (int i=0; i<responseLines.length; i++) {
                      responseLines[i] = truncate(responseLines[i], width - 6);
                   }
                   responseScrollOffset = 0;
                   quickRunUrl = ''; // Clear quick run so esc goes to list
                   currentView = 'response';
                   render();
                }
             } else if (k == 106) { // j / down
                selectedReq++;
                render();
             } else if (k == 107) { // k / up
                if (selectedReq > 0) selectedReq--;
                render();
             }
          }
       } else if (currentView == 'envs') {
          if (keyBytes.length == 1 && keyBytes[0] == 27) { // ESC
             currentView = 'menu';
             render();
          }
       } else if (currentView == 'quickrun') {
          if (keyBytes.length == 1) {
             int k = keyBytes[0];
             if (k == 27) { // ESC
                quickRunUrl = '';
                currentView = 'menu';
                render();
             } else if (k == 103 || k == 71) { // g or G
                quickRunMethod = 'GET'; render();
             } else if (k == 112 || k == 80) { // p or P
                quickRunMethod = 'POST'; render();
             } else if (k == 117 || k == 85) { // u or U
                quickRunMethod = 'PUT'; render();
             } else if (k == 100 || k == 68) { // d or D
                quickRunMethod = 'DELETE'; render();
             } else if (k == 13 || k == 10) { // ENTER
                if (quickRunUrl.isNotEmpty) {
                   stdout.write('\x1B[2J\x1B[H');
                   stdout.write('  🚀 Running $quickRunMethod $quickRunUrl...\n');
                   final ctx = HttpRequestContext(
                      method: quickRunMethod,
                      url: quickRunUrl,
                      timeoutMs: 30000,
                   );
                   lastResult = await executeHttpRequest(ctx);
                   
                   final data = lastResult!['data'] as Map<String, dynamic>? ?? {};
                   final lowerHeaders = (data['headers'] as Map? ?? {}).map((k, v) => MapEntry(k.toString().toLowerCase(), v.toString()));
                   String bodyStr = data['body']?.toString() ?? '';
                   if ((lowerHeaders['content-type'] ?? '').contains('text/html')) {
                      responseLines = [
                        '[HTML Response — use a browser to view this URL]',
                        'Tip: Try a JSON API endpoint instead, e.g. https://httpbin.org/get'
                      ];
                   } else {
                      try {
                        final decoded = jsonDecode(bodyStr);
                        bodyStr = JsonEncoder.withIndent('  ').convert(decoded);
                      } catch (_) {}
                      responseLines = bodyStr.split('\n');
                   }
                   
                   int width = stdout.terminalColumns;
                   for (int i=0; i<responseLines.length; i++) {
                      responseLines[i] = truncate(responseLines[i], width - 6);
                   }
                   responseScrollOffset = 0;
                   currentView = 'response';
                   render();
                }
             } else if (k == 127 || k == 8) { // Backspace
                if (quickRunUrl.isNotEmpty) {
                   quickRunUrl = quickRunUrl.substring(0, quickRunUrl.length - 1);
                   render();
                }
             } else if (k >= 32 && k < 127) { // Printable chars
                quickRunUrl += String.fromCharCode(k);
                render();
             }
          }
       } else if (currentView == 'search') {
          if (keyBytes.length == 1) {
             int k = keyBytes[0];
             if (k == 27) { // ESC
                searchTerm = '';
                currentView = 'list';
                render();
             } else if (k == 13 || k == 10) { // ENTER
                currentView = 'list';
                render();
             } else if (k == 127 || k == 8) { // Backspace
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
          } else if (keyBytes.length == 3 && keyBytes[0] == 27 && keyBytes[1] == 91) {
             if (keyBytes[2] == 65) { // Up
                if (selectedReq > 0) selectedReq--;
                render();
             } else if (keyBytes[2] == 66) { // Down
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
    stdout.write('\x1B[2J\x1B[H'); // Clear
  }
}
'''

with open('bin/apidash_cli.dart', 'w') as f:
    f.write(orig[:start_idx] + new_run_interactive + orig[end_idx:])

