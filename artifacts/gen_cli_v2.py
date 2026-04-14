import json

with open('bin/apidash_cli.dart', 'r') as f:
    orig = f.read()

# We need to replace `runInteractive` implementation
# It starts at `Future<void> runInteractive()` up to `void main(List<String> args) async {`

target_start = "Future<void> runInteractive() async {"
target_end = "void main(List<String> args) async {"

start_idx = orig.find(target_start)
end_idx = orig.find(target_end)

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
  
  String currentView = 'menu'; // menu, list, search, response
  
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

  [1] Browse Requests    [2] Run Request
  [3] Environments       [4] Search
  [5] Quick Send         [Q] Quit""");
        
        stdout.write('\x1B[${height}H'); 
        stdout.write('  [1-5] Select option   [Q] Quit');
        
      } else if (currentView == 'response') {
        // Just print the beautiful response and wait for a key
        if (lastResult != null) {
          printBeautifulResponse(lastResult!);
        }
        stdout.write('\x1B[${height}H'); 
        stdout.write('  Press any key to go back...');
        
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
        
        int listHeight = math.max(1, height - 6);
        if (scrollOffset > selectedReq) scrollOffset = selectedReq;
        if (selectedReq >= scrollOffset + listHeight) scrollOffset = selectedReq - listHeight + 1;
        if (scrollOffset > math.max(0, results.length - listHeight)) scrollOffset = math.max(0, results.length - listHeight);
        
        if (currentView == 'search') {
          print("  🔍 Search: $searchTerm_");
        } else {
          print("  📋 $bold Browse Requests (${results.length})$reset");
        }
        print(""); // Empty line

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
           
           String row = '  $mPad $nPad $uPad';
           
           if (i == selectedReq) {
              // Highlight selected row with reverse video (\x1B[7m) and clear other colors for the selection block
              stdout.write('\x1B[7m' + padRight('  $m $rawN $rawU', width) + '\x1B[0m\n');
           } else {
              stdout.write('  ${colorMethod(mPad)} $nPad ${gray}$uPad$reset\n');
           }
        }
        
        // Scroll indicators
        if (results.length > listHeight) {
          String ind = "  " + (scrollOffset > 0 ? "↑ more" : "") + " " + (endIdx < results.length ? "↓ more" : "");
          stdout.write('\x1B[${height - 1}H' + ind);
        }
        
        stdout.write('\x1B[${height}H'); 
        if (currentView == 'search') {
          stdout.write('  [ESC] Clear/Exit search   [ENTER] Select   Type to filter...');
        } else {
          stdout.write('  [↑/↓] Navigate   [ENTER] Run   [/] Search   [ESC] Menu');
        }
      }
    }

    render();

    await for (var keyBytes in stdin) {
       if (keyBytes.isEmpty) continue;
       
       if (currentView == 'response') {
          currentView = 'list';
          render();
          continue;
       }
       
       if (currentView == 'menu') {
          int k = keyBytes[0];
          if (k == 113 || k == 81 || k == 27) { // q or Q or ESC
             break;
          } else if (k == 49) { // 1
             currentView = 'list';
             selectedReq = 0;
             scrollOffset = 0;
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

new_content = orig[:start_idx] + new_run_interactive + orig[end_idx:]

with open('bin/apidash_cli.dart', 'w') as f:
    f.write(new_content)

