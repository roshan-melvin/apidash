import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../tools/tool_ui_helper.dart';

// ─── Shared HTML builders — used by both Resources and Tool EmbeddedResource returns ─

String buildRequestBuilderHtml() {
  final requests = WorkspaceState().requests;
  final rows = requests.isEmpty
      ? '<tr><td colspan="3" class="empty">No requests yet — open APIDash and save one.</td></tr>'
      : requests.map((r) {
          final method = (r['method'] as String? ?? 'GET').toUpperCase();
          final name = (r['name'] as String? ?? '').isEmpty ? '(unnamed)' : r['name'] as String;
          final url = r['url'] as String? ?? '';
          final status = r['responseStatus'];
          final statusHtml = status == null
              ? '<span style="color:var(--muted)">—</span>'
              : '<span class="${(status as int) < 300 ? 'ok' : (status < 500 ? 'warn' : 'err')}">$status</span>';
          return '<tr><td><span class="badge ${methodClass(method)}">$method</span></td>'
              '<td>${htmlEsc(name)}<br><small style="color:var(--muted);font-size:.72rem">${htmlEsc(url)}</small></td>'
              '<td>$statusHtml</td></tr>';
        }).join();

  return buildHtmlShell(
    title: 'Request Builder',
    body: '''
<h1>✏️ Request Builder</h1>
<div class="card">
  <table>
    <thead><tr><th>Method</th><th>Name / URL</th><th>Status</th></tr></thead>
    <tbody>$rows</tbody>
  </table>
</div>
<p style="font-size:.76rem;color:var(--muted);margin-top:4px">
  ${requests.length} request(s) in workspace. Use <code>http-send-request</code> to send new requests.
</p>''',
  );
}

String buildResponseViewerHtml() {
  final last = WorkspaceState().lastResponse;
  String body;
  if (last == null) {
    body = '<div class="empty">No response yet.<br>Send a request in APIDash first.</div>';
  } else {
    final status = last['responseStatus'] ?? 0;
    final statusInt = status as int;
    final cls = statusInt < 300 ? 'ok' : (statusInt < 500 ? 'warn' : 'err');
    final responseBody = htmlEsc(last['body']?.toString() ?? '(empty)');
    final headers = (last['headers'] as Map?) ?? {};
    final headerRows = headers.entries
        .map((e) => '<tr><td>${htmlEsc(e.key.toString())}</td><td>${htmlEsc(e.value.toString())}</td></tr>')
        .join();
    final duration = last['duration'] != null ? '${last['duration']} ms' : '';
    final name = htmlEsc(last['name']?.toString() ?? '');
    body = '''
<div class="card" style="border-left:3px solid var(--${cls == 'ok' ? 'accent2' : cls == 'warn' ? 'warn' : 'err'})">
  <span style="font-size:1.5rem;font-weight:700" class="$cls">$status</span>
  <span style="color:var(--muted);margin-left:10px">$name</span>
  <span style="color:var(--muted);float:right;font-size:.74rem">$duration</span>
</div>
<h2>Body</h2>
<pre>$responseBody</pre>
<h2>Headers</h2>
<div class="card">
  <table><thead><tr><th>Header</th><th>Value</th></tr></thead>
  <tbody>$headerRows</tbody></table>
</div>''';
  }
  return buildHtmlShell(title: 'Response Viewer', body: '<h1>📄 Response Viewer</h1>\n$body');
}

String buildCollectionsExplorerHtml() {
  final requests = WorkspaceState().requests;
  final items = requests.isEmpty
      ? '<div class="empty">No requests. Open APIDash and save one.</div>'
      : requests.map((r) {
          final method = (r['method'] as String? ?? 'GET').toUpperCase();
          final name = (r['name'] as String? ?? '').isEmpty ? '(unnamed)' : r['name'] as String;
          final url = r['url'] as String? ?? '';
          return '''<div class="card row">
  <span class="badge ${methodClass(method)}" style="flex-shrink:0;margin-top:2px">$method</span>
  <div style="flex:1;min-width:0">
    <div style="font-weight:600;font-size:.86rem">${htmlEsc(name)}</div>
    <div style="color:var(--muted);font-size:.73rem;word-break:break-all">${htmlEsc(url)}</div>
  </div>
</div>''';
        }).join('\n');

  return buildHtmlShell(
    title: 'Collections Explorer',
    body: '<h1>📁 Collections Explorer</h1>'
        '<p style="font-size:.76rem;color:var(--muted);margin-bottom:12px">${requests.length} request(s)</p>'
        '$items',
  );
}

String buildGraphqlExplorerHtml() {
  return buildHtmlShell(
    title: 'GraphQL Explorer',
    body: '''
<h1>⬡ GraphQL Explorer</h1>
<div class="card">
  <h2>How to use</h2>
  <p style="font-size:.82rem;color:var(--muted);margin-top:6px">
    Use <strong style="color:var(--accent)">graphql-execute-query</strong> to run queries or mutations.
  </p>
</div>
<h2>Example introspection query</h2>
<pre>{ __schema { queryType { name } types { name kind } } }</pre>
<div class="card">
  <span class="pill">graphql-explorer</span> — schema introspection<br><br>
  <span class="pill">graphql-execute-query</span> — run queries &amp; mutations
</div>''',
  );
}

String buildCodeGeneratorHtml({String? method, String? url}) {
  final pills = supportedGenerators.map((g) => '<span class="pill">$g</span>').join('');
  final requestInfo = (method != null && url != null)
      ? '<p style="font-size:.76rem;color:var(--muted);margin-bottom:12px">'
          'Pre-loaded: <code>${htmlEsc(method)} ${htmlEsc(url)}</code></p>'
      : '';
  return buildHtmlShell(
    title: 'Code Generator',
    body: '''
<h1>&lt;/&gt; Code Generator</h1>
$requestInfo
<div class="card">
  <h2>Supported languages (${supportedGenerators.length})</h2>
  <div style="margin-top:8px">$pills</div>
</div>
<div class="card">
  <h2>How to use</h2>
  <p style="font-size:.82rem;color:var(--muted);margin-top:6px">
    Use <strong style="color:var(--accent)">generate-code-snippet</strong> with a specific language.
  </p>
</div>''',
  );
}

String buildEnvManagerHtml() {
  final envs = WorkspaceState().environments;
  String content;
  if (envs.isEmpty) {
    content = '<div class="empty">No environments. Add them in APIDash.</div>';
  } else {
    content = envs.map((env) {
      final name = htmlEsc(env['name']?.toString() ?? 'Unnamed');
      final vars = env['variables'] as List? ?? [];
      final varRows = vars.isEmpty
          ? '<tr><td colspan="2" style="color:var(--muted)">No variables</td></tr>'
          : vars.cast<Map>().map((v) {
              final enabled = v['enabled'] != false;
              return '<tr style="${enabled ? '' : 'opacity:.4'}">'
                  '<td>${htmlEsc(v['key']?.toString() ?? '')}</td>'
                  '<td>${htmlEsc(v['value']?.toString() ?? '')}</td></tr>';
            }).join();
      return '''<div class="card">
  <div style="font-weight:600;color:var(--accent);margin-bottom:8px">
    $name <span style="color:var(--muted);font-weight:400;font-size:.74rem">(${vars.length} vars)</span>
  </div>
  <table><thead><tr><th>Key</th><th>Value</th></tr></thead>
  <tbody>$varRows</tbody></table>
</div>''';
    }).join('\n');
  }
  return buildHtmlShell(title: 'Environment Manager', body: '<h1>⚙️ Environment Manager</h1>\n$content');
}

String buildCodeViewerHtml() {
  const tools = [
    ('http-send-request', 'Send any HTTP request', '#58a6ff'),
    ('request-builder', 'Build and send HTTP requests', '#58a6ff'),
    ('view-response', 'Show last response panel', '#58a6ff'),
    ('graphql-explorer', 'Introspect a GraphQL schema', '#bc8cff'),
    ('graphql-execute-query', 'Run GraphQL query or mutation', '#bc8cff'),
    ('generate-code-snippet', 'Generate code in a specific language', '#f0883e'),
    ('codegen-ui', 'Code snippets for all languages', '#f0883e'),
    ('ai-llm-request', 'Call any AI/LLM provider', '#3fb950'),
    ('explore-collections', 'List workspace requests', '#39c5cf'),
    ('get-last-response', 'Get last APIDash response', '#39c5cf'),
    ('manage-environment', 'List all environments', '#39c5cf'),
    ('save-request', 'Queue a new request to workspace', '#39c5cf'),
    ('get-api-request-template', 'Get a blank request template', '#8b949e'),
    ('update-environment-variables', 'Manage env variables', '#8b949e'),
  ];
  final rows = tools.map((t) =>
      '<tr><td><code style="color:${t.$3}">${t.$1}</code></td>'
      '<td style="color:var(--muted)">${t.$2}</td></tr>').join();

  return buildHtmlShell(
    title: 'APIDash MCP — Tool Reference',
    body: '''
<h1>⊞ APIDash MCP — All Tools</h1>
<div class="card">
  <table>
    <thead><tr><th>Tool</th><th>What it does</th></tr></thead>
    <tbody>$rows</tbody>
  </table>
</div>''',
  );
}
