import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';

// ─── Shared HTML shell ────────────────────────────────────────────────────────

/// Wraps panel content in an APIDash-branded dark HTML page.
/// Agents render this as an embedded iframe/sandbox panel.
String _htmlShell({required String title, required String body}) =>
    '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>$title – APIDash MCP</title>
<style>
  :root{--bg:#0d1117;--surface:#161b22;--border:#30363d;--accent:#58a6ff;--accent2:#3fb950;--warn:#f0883e;--text:#e6edf3;--muted:#8b949e;--mono:'Fira Code',monospace}
  *{box-sizing:border-box;margin:0;padding:0}
  body{font-family:Inter,system-ui,sans-serif;background:var(--bg);color:var(--text);min-height:100vh;padding:16px}
  h1{font-size:1.1rem;font-weight:700;color:var(--accent);margin-bottom:12px;display:flex;align-items:center;gap:8px}
  h2{font-size:.85rem;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.06em;margin:14px 0 6px}
  .card{background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:12px;margin-bottom:10px}
  .badge{display:inline-block;padding:2px 7px;border-radius:4px;font-size:.72rem;font-weight:700;text-transform:uppercase}
  .badge-get{background:#1f3d5e;color:#58a6ff}.badge-post{background:#1e3a2c;color:#3fb950}
  .badge-put{background:#3b2e00;color:#f0883e}.badge-patch{background:#2d1f52;color:#bc8cff}
  .badge-delete{background:#3d1c1c;color:#f85149}.badge-head{background:#1f3a3a;color:#39c5cf}
  pre{font-family:var(--mono);font-size:.78rem;background:#010409;border:1px solid var(--border);border-radius:6px;padding:10px;overflow-x:auto;white-space:pre-wrap;word-break:break-all;color:#c9d1d9;max-height:260px;overflow-y:auto}
  table{width:100%;border-collapse:collapse;font-size:.82rem}
  th{text-align:left;color:var(--muted);font-weight:600;border-bottom:1px solid var(--border);padding:4px 8px}
  td{padding:5px 8px;border-bottom:1px solid #21262d;vertical-align:top}
  td:first-child{color:var(--accent);font-family:var(--mono);font-size:.78rem}
  .empty{color:var(--muted);font-size:.85rem;text-align:center;padding:24px}
  .pill{display:inline-flex;align-items:center;gap:4px;background:#21262d;border:1px solid var(--border);border-radius:20px;padding:3px 9px;font-size:.75rem;margin:3px 2px}
  footer{margin-top:16px;font-size:.7rem;color:var(--muted);text-align:center}
</style>
</head>
<body>
$body
<footer>APIDash MCP Server · mcp_dart v2.1.0</footer>
</body>
</html>''';

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

// ─── Resource metadata record helper ─────────────────────────────────────────
// ResourceMetadata is a Dart record typedef: ({String? description, String? mimeType})

// ─── Request Builder Resource ────────────────────────────────────────────────

void registerRequestBuilderResource(McpServer server) {
  server.registerResource(
    'request-builder-ui',
    'ui://apidash-mcp/request-builder',
    (description: 'Interactive panel showing all workspace requests.', mimeType: 'text/html'),
    (Uri uri, RequestHandlerExtra extra) async {
      final requests = WorkspaceState().requests;
      final rows = requests.isEmpty
          ? '<tr><td colspan="3" class="empty">No requests — open APIDash and save one.</td></tr>'
          : requests.map((r) {
              final method = (r['method'] as String? ?? 'GET').toUpperCase();
              final name = (r['name'] as String? ?? '').isEmpty ? '(unnamed)' : r['name'] as String;
              final url = r['url'] as String? ?? '';
              final badgeCls = 'badge badge-${method.toLowerCase()}';
              final status = r['responseStatus'];
              final statusHtml = status != null
                  ? '<span style="color:${(status as int) < 300 ? 'var(--accent2)' : 'var(--warn)'}">$status</span>'
                  : '<span style="color:var(--muted)">—</span>';
              return '<tr><td><span class="$badgeCls">$method</span></td>'
                  '<td>${_esc(name)}<br><small style="color:var(--muted)">${_esc(url)}</small></td>'
                  '<td>$statusHtml</td></tr>';
            }).join();

      final html = _htmlShell(
        title: 'Request Builder',
        body: '''
<h1>✏️ Request Builder</h1>
<div class="card">
  <table>
    <thead><tr><th>Method</th><th>Name / URL</th><th>Last Status</th></tr></thead>
    <tbody>$rows</tbody>
  </table>
</div>
<p style="font-size:.78rem;color:var(--muted)">
  ${requests.length} request(s) synced. Use <strong>http-send-request</strong> to send new requests.
</p>''',
      );

      return ReadResourceResult(
        contents: [
          TextResourceContents(uri: uri.toString(), mimeType: 'text/html', text: html),
        ],
      );
    },
    title: 'Request Builder',
  );
}

// ─── Response Viewer Resource ─────────────────────────────────────────────────

void registerResponseViewerResource(McpServer server) {
  server.registerResource(
    'response-viewer-ui',
    'ui://apidash-mcp/response-viewer',
    (description: 'Displays the last HTTP response received in APIDash.', mimeType: 'text/html'),
    (Uri uri, RequestHandlerExtra extra) async {
      final last = WorkspaceState().lastResponse;

      String bodyHtml;
      if (last == null) {
        bodyHtml = '<div class="empty">No response yet — send a request in APIDash first.</div>';
      } else {
        final status = last['responseStatus'] ?? 0;
        final statusColor = (status as int) < 300 ? 'var(--accent2)' : 'var(--warn)';
        final responseBody = _esc(last['body']?.toString() ?? '(empty)');
        final headers = last['headers'] as Map? ?? {};
        final headerRows = headers.entries
            .map((e) => '<tr><td>${_esc(e.key.toString())}</td><td>${_esc(e.value.toString())}</td></tr>')
            .join();

        bodyHtml = '''
<div class="card" style="border-left:3px solid $statusColor">
  <div style="display:flex;gap:12px;align-items:center;margin-bottom:8px">
    <span style="font-size:1.4rem;font-weight:700;color:$statusColor">$status</span>
    <span style="color:var(--muted)">· ${_esc(last['name']?.toString() ?? '')}</span>
    <span style="color:var(--muted);margin-left:auto;font-size:.75rem">${last['duration'] != null ? '${last['duration']} ms' : ''}</span>
  </div>
</div>
<h2>Response Body</h2>
<pre>$responseBody</pre>
<h2>Response Headers</h2>
<div class="card">
  <table><thead><tr><th>Header</th><th>Value</th></tr></thead>
  <tbody>$headerRows</tbody></table>
</div>''';
      }

      final html = _htmlShell(
        title: 'Response Viewer',
        body: '<h1>📄 Response Viewer</h1>\n$bodyHtml',
      );

      return ReadResourceResult(
        contents: [
          TextResourceContents(uri: uri.toString(), mimeType: 'text/html', text: html),
        ],
      );
    },
    title: 'Response Viewer',
  );
}

// ─── Collections Explorer Resource ───────────────────────────────────────────

void registerCollectionsExplorerResource(McpServer server) {
  server.registerResource(
    'collections-explorer-ui',
    'ui://apidash-mcp/collections-explorer',
    (description: 'Browse all API requests from the APIDash workspace.', mimeType: 'text/html'),
    (Uri uri, RequestHandlerExtra extra) async {
      final requests = WorkspaceState().requests;

      final items = requests.isEmpty
          ? '<div class="empty">No collections synced. Open APIDash and save a request.</div>'
          : requests.map((r) {
              final method = (r['method'] as String? ?? 'GET').toUpperCase();
              final name = (r['name'] as String? ?? '').isEmpty ? '(unnamed)' : r['name'] as String;
              final url = r['url'] as String? ?? '';
              final isWorking = r['isWorking'] == true;
              return '''<div class="card" style="display:flex;gap:10px;align-items:flex-start">
  <span class="badge badge-${method.toLowerCase()}" style="margin-top:2px">$method</span>
  <div style="flex:1;min-width:0">
    <div style="font-weight:600;font-size:.88rem">${_esc(name)}${isWorking ? ' ⟳' : ''}</div>
    <div style="color:var(--muted);font-size:.75rem;word-break:break-all">${_esc(url)}</div>
  </div>
</div>''';
            }).join('\n');

      final html = _htmlShell(
        title: 'Collections Explorer',
        body: '''
<h1>📁 Collections Explorer</h1>
<p style="font-size:.78rem;color:var(--muted);margin-bottom:12px">${requests.length} request(s) in workspace</p>
$items''',
      );

      return ReadResourceResult(
        contents: [
          TextResourceContents(uri: uri.toString(), mimeType: 'text/html', text: html),
        ],
      );
    },
    title: 'Collections Explorer',
  );
}

// ─── GraphQL Explorer Resource ────────────────────────────────────────────────

void registerGraphqlExplorerResource(McpServer server) {
  const exampleQuery = r'''
{
  __schema {
    queryType { name }
    types {
      name
      kind
      description
    }
  }
}''';

  server.registerResource(
    'graphql-explorer-ui',
    'ui://apidash-mcp/graphql-explorer',
    (description: 'GraphQL explorer panel with usage guide and example queries.', mimeType: 'text/html'),
    (Uri uri, RequestHandlerExtra extra) async {
      final html = _htmlShell(
        title: 'GraphQL Explorer',
        body: '''
<h1>⬡ GraphQL Explorer</h1>
<div class="card">
  <h2>How to use</h2>
  <p style="font-size:.82rem;color:var(--muted);margin-top:6px">
    Ask the agent to use the <strong style="color:var(--accent)">graphql-explorer</strong> tool to
    introspect a schema, or <strong style="color:var(--accent)">graphql-execute-query</strong> to run queries.
  </p>
</div>
<h2>Example introspection query</h2>
<pre>${_esc(exampleQuery)}</pre>
<div class="card">
  <div style="margin-top:4px"><span class="pill">graphql-explorer</span> — schema introspection</div>
  <div style="margin-top:4px"><span class="pill">graphql-execute-query</span> — run queries &amp; mutations</div>
</div>''',
      );

      return ReadResourceResult(
        contents: [
          TextResourceContents(uri: uri.toString(), mimeType: 'text/html', text: html),
        ],
      );
    },
    title: 'GraphQL Explorer',
  );
}

// ─── Code Generator Resource ──────────────────────────────────────────────────

void registerCodeGeneratorResource(McpServer server) {
  server.registerResource(
    'code-generator-ui',
    'ui://apidash-mcp/code-generator',
    (description: 'Code snippet generator — shows all ${supportedGenerators.length} supported languages.', mimeType: 'text/html'),
    (Uri uri, RequestHandlerExtra extra) async {
      final pills = supportedGenerators.map((g) => '<span class="pill">$g</span>').join('');

      final html = _htmlShell(
        title: 'Code Generator',
        body: '''
<h1>&lt;/&gt; Code Generator</h1>
<div class="card">
  <h2>Supported languages (${supportedGenerators.length})</h2>
  <div style="margin-top:8px">$pills</div>
</div>
<div class="card">
  <h2>How to use</h2>
  <p style="font-size:.82rem;color:var(--muted);margin-top:6px">
    Ask: <em>"Generate a Python requests snippet for GET https://api.example.com/users"</em><br>
    Or use <strong style="color:var(--accent)">codegen-ui</strong> to get all languages at once.
  </p>
</div>''',
      );

      return ReadResourceResult(
        contents: [
          TextResourceContents(uri: uri.toString(), mimeType: 'text/html', text: html),
        ],
      );
    },
    title: 'Code Generator',
  );
}

// ─── Environment Manager Resource ─────────────────────────────────────────────

void registerEnvManagerResource(McpServer server) {
  server.registerResource(
    'env-manager-ui',
    'ui://apidash-mcp/env-manager',
    (description: 'Environment variable manager — shows all APIDash environments.', mimeType: 'text/html'),
    (Uri uri, RequestHandlerExtra extra) async {
      final envs = WorkspaceState().environments;

      String content;
      if (envs.isEmpty) {
        content = '<div class="empty">No environments synced.<br>Add environments in APIDash and save them.</div>';
      } else {
        content = envs.map((env) {
          final name = _esc(env['name']?.toString() ?? 'Unnamed');
          final vars = env['variables'] as List? ?? [];
          final varRows = vars.isEmpty
              ? '<tr><td colspan="2" style="color:var(--muted);font-size:.78rem">No variables</td></tr>'
              : vars.cast<Map>().map((v) {
                  final enabled = v['enabled'] != false;
                  final key = _esc(v['key']?.toString() ?? '');
                  final val = _esc(v['value']?.toString() ?? '');
                  return '<tr style="${enabled ? '' : 'opacity:.45'}">'
                      '<td>$key</td><td>$val</td></tr>';
                }).join();

          return '''<div class="card">
  <h2>$name <span style="color:var(--muted);font-size:.7rem">(${vars.length} vars)</span></h2>
  <table style="margin-top:6px">
    <thead><tr><th>Key</th><th>Value</th></tr></thead>
    <tbody>$varRows</tbody>
  </table>
</div>''';
        }).join('\n');
      }

      final html = _htmlShell(
        title: 'Environment Manager',
        body: '<h1>⚙️ Environment Manager</h1>\n$content',
      );

      return ReadResourceResult(
        contents: [
          TextResourceContents(uri: uri.toString(), mimeType: 'text/html', text: html),
        ],
      );
    },
    title: 'Environment Manager',
  );
}

// ─── Code Viewer / Tool Reference Resource ────────────────────────────────────

void registerCodeViewerResource(McpServer server) {
  server.registerResource(
    'code-viewer-ui',
    'ui://apidash-mcp/code-viewer',
    (description: 'APIDash MCP — all 14 tools and 7 resources at a glance.', mimeType: 'text/html'),
    (Uri uri, RequestHandlerExtra extra) async {
      const tools = [
        ('http-send-request',        'Send any HTTP request',                   '#58a6ff'),
        ('request-builder',          'Build and send HTTP requests',            '#58a6ff'),
        ('view-response',            'Send request and format the response',    '#58a6ff'),
        ('graphql-explorer',         'Introspect a GraphQL schema',             '#bc8cff'),
        ('graphql-execute-query',    'Run a GraphQL query or mutation',         '#bc8cff'),
        ('generate-code-snippet',    'Generate code in a specific language',    '#f0883e'),
        ('codegen-ui',               'Code snippets for ALL languages',         '#f0883e'),
        ('ai-llm-request',           'Call any AI/LLM provider',               '#3fb950'),
        ('get-api-request-template', 'Get a blank request template',           '#8b949e'),
        ('explore-collections',      'List workspace requests',                 '#39c5cf'),
        ('get-last-response',        'Get last APIDash response',              '#39c5cf'),
        ('manage-environment',       'List all environments',                   '#39c5cf'),
        ('save-request',             'Queue a new request to workspace',        '#39c5cf'),
        ('update-environment-variables', 'Search env variables',               '#39c5cf'),
      ];

      final rows = tools.map((t) =>
        '<tr><td><code style="color:${t.$3}">${t.$1}</code></td>'
        '<td style="color:var(--muted)">${t.$2}</td></tr>'
      ).join();

      final resourceUris = [
        'ui://apidash-mcp/request-builder',
        'ui://apidash-mcp/response-viewer',
        'ui://apidash-mcp/collections-explorer',
        'ui://apidash-mcp/graphql-explorer',
        'ui://apidash-mcp/code-generator',
        'ui://apidash-mcp/env-manager',
        'ui://apidash-mcp/code-viewer',
      ];
      final resourcePills = resourceUris.map((u) => '<span class="pill">$u</span>').join(' ');

      final html = _htmlShell(
        title: 'APIDash MCP — All Tools',
        body: '''
<h1>⊞ APIDash MCP — Tool Reference</h1>
<div class="card">
  <table>
    <thead><tr><th>Tool name</th><th>What it does</th></tr></thead>
    <tbody>$rows</tbody>
  </table>
</div>
<div class="card">
  <h2>Resources (UI panels)</h2>
  <div style="margin-top:6px">$resourcePills</div>
</div>''',
      );

      return ReadResourceResult(
        contents: [
          TextResourceContents(uri: uri.toString(), mimeType: 'text/html', text: html),
        ],
      );
    },
    title: 'APIDash MCP — Tool Reference',
  );
}
