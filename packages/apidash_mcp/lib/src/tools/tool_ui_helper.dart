import 'package:mcp_dart/mcp_dart.dart';

// ─── RFC 3986 compliant URI scheme ───────────────────────────────────────────
// ui://apidash-mcp/<panel>
// ✓ hyphen in authority (legal)   ✗ underscore (illegal per RFC 3986)
// ✓ ui:// scheme (SEP-1865)       ✗ apidash:// (unregistered, webview drops it)

const _base = 'ui://apidash-mcp';

const kUriRequestBuilder      = '$_base/request-builder';
const kUriResponseViewer      = '$_base/response-viewer';
const kUriCollectionsExplorer = '$_base/collections-explorer';
const kUriGraphqlExplorer     = '$_base/graphql-explorer';
const kUriCodeGenerator       = '$_base/code-generator';
const kUriEnvManager          = '$_base/env-manager';
const kUriCodeViewer          = '$_base/code-viewer';

// ─── Tool result ─────────────────────────────────────────────────────────────

/// Build a [CallToolResult] that follows the SEP-1865 App lifecycle:
///   1. Returns a brief text confirmation visible in chat
///   2. Sets `_meta.ui.resourceUri` so the host fires `resources/read`
///   3. Returns empty `structuredContent` (required by VS Code renderer)
///   4. Host renders the HTML returned by the resource as the iframe panel
CallToolResult uiToolResult({
  required String resourceUri,
  required String confirmationText,
}) {
  return CallToolResult(
    content: [TextContent(text: confirmationText)],
    structuredContent: <String, dynamic>{},
    meta: {
      'ui': {
        'resourceUri': resourceUri,
        'visibility': ['model', 'app'],
      },
    },
  );
}



// ─── Shared HTML shell ────────────────────────────────────────────────────────

/// APIDash dark-theme HTML shell for all resource panels.
String buildHtmlShell({required String title, required String body}) =>
    '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>$title – APIDash MCP</title>
<style>
  :root{--bg:#0d1117;--surface:#161b22;--border:#30363d;--accent:#58a6ff;--accent2:#3fb950;--warn:#f0883e;--err:#f85149;--text:#e6edf3;--muted:#8b949e;--mono:'Fira Code',Consolas,monospace}
  *{box-sizing:border-box;margin:0;padding:0}
  body{font-family:Inter,system-ui,sans-serif;background:var(--bg);color:var(--text);min-height:100vh;padding:16px 18px}
  h1{font-size:1.05rem;font-weight:700;color:var(--accent);margin-bottom:14px;display:flex;align-items:center;gap:8px}
  h2{font-size:.78rem;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.07em;margin:14px 0 6px}
  .card{background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:12px 14px;margin-bottom:10px}
  .badge{display:inline-block;padding:2px 8px;border-radius:4px;font-size:.7rem;font-weight:700;text-transform:uppercase;letter-spacing:.03em}
  .get{background:#1f3d5e;color:#58a6ff}.post{background:#1e3a2c;color:#3fb950}
  .put{background:#3b2e00;color:#f0883e}.patch{background:#2d1f52;color:#bc8cff}
  .delete{background:#3d1c1c;color:#f85149}.head{background:#1f3a3a;color:#39c5cf}
  pre,code{font-family:var(--mono);font-size:.76rem}
  pre{background:#010409;border:1px solid var(--border);border-radius:6px;padding:10px 12px;overflow-x:auto;white-space:pre-wrap;word-break:break-all;color:#c9d1d9;max-height:280px;overflow-y:auto;margin:6px 0}
  table{width:100%;border-collapse:collapse;font-size:.81rem}
  th{text-align:left;color:var(--muted);font-weight:600;border-bottom:1px solid var(--border);padding:5px 8px}
  td{padding:5px 8px;border-bottom:1px solid #21262d;vertical-align:top;word-break:break-all}
  td:first-child{color:var(--accent);font-family:var(--mono);font-size:.76rem;white-space:nowrap;word-break:normal}
  .empty{color:var(--muted);font-size:.84rem;text-align:center;padding:28px}
  .pill{display:inline-flex;align-items:center;background:#21262d;border:1px solid var(--border);border-radius:20px;padding:3px 10px;font-size:.73rem;margin:3px 2px}
  .row{display:flex;gap:10px;align-items:flex-start}
  .ok{color:var(--accent2)}.warn{color:var(--warn)}.err{color:var(--err)}
  footer{margin-top:18px;font-size:.68rem;color:var(--muted);text-align:center;opacity:.7}
</style>
</head>
<body>
$body
<footer>APIDash MCP · mcp_dart v2.1.0</footer>
</body>
</html>''';

/// HTML-escape a string for safe embedding.
String htmlEsc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// CSS badge class for an HTTP method.
String methodClass(String method) => method.toLowerCase();
