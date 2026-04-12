/// GraphQL Explorer panel — ported from the TS PoC.
library;

import '../styles.dart';

String buildGraphqlExplorerPanel() {
  return buildPanelHtml(
    title: 'APIDash · GraphQL Explorer',
    panelStyles: graphqlStyles,
    body: '''
  <div class="header">
    <span class="header-title">🌍 APIDash GraphQL</span>
    <span class="header-subtitle">Execute GraphQL queries</span>
    <div style="margin-left:auto; display:flex; gap:6px; align-items:center;">
      <span class="statusbar" id="connStatus">Connecting…</span>
      <button class="btn-primary" id="runBtn" onclick="runQuery()">
        ▶ Run Query
      </button>
    </div>
  </div>

  <div class="main">
    <div class="endpoint-row">
      <div class="badge badge-post" style="padding:4px 8px; font-size:11px;">POST</div>
      <input type="text" id="urlInput" class="gql-url" placeholder="https://api.github.com/graphql" />
    </div>
    
    <div class="editor-panes">
      <div class="editor-pane">
        <div class="editor-label">
          <span>Query</span>
          <div style="display:flex; gap:4px;">
            <button class="btn-secondary" style="padding:2px 6px; font-size:9px;" onclick="formatQuery()">Format</button>
          </div>
        </div>
        <textarea id="queryInput" class="gql-textarea" placeholder="query { ... }"></textarea>
        
        <div class="editor-label" style="border-top:1px solid var(--border);">Variables (JSON)</div>
        <textarea id="varsInput" class="gql-textarea" style="flex:0.5;" placeholder='{ "id": 1 }'></textarea>
      </div>
      
      <div class="editor-pane">
        <div class="editor-label">
          <span>Result</span>
          <div style="display:flex; gap:8px; align-items:center;">
            <span id="execTime" style="font-family:var(--mono); color:var(--muted); font-size:9px;"></span>
            <span id="statusCode" style="font-family:var(--mono); font-weight:700; font-size:10px;"></span>
          </div>
        </div>
        <div id="resultBox" class="result-box">
          <div id="resultPlaceholder" style="color:var(--muted); text-align:center; padding:40px 10px;">
            Run a query to see results
          </div>
          <div id="resultContent" style="display:none;"></div>
        </div>
      </div>
    </div>
  </div>

  <script>
    const pending = new Map();
    let nextId = 1;
    let lastResponse = null;

    function request(method, params) {
      const id = nextId++;
      return new Promise((resolve, reject) => {
        pending.set(id, { resolve, reject });
        window.parent.postMessage({ jsonrpc: '2.0', id, method, params }, '*');
      });
    }

    function notify(method, params) {
      window.parent.postMessage({ jsonrpc: '2.0', method, params }, '*');
    }

    window.addEventListener('message', (event) => {
      const msg = event.data;
      if (!msg) return;
      if (msg.id && pending.has(msg.id)) {
        const { resolve, reject } = pending.get(msg.id);
        pending.delete(msg.id);
        if (msg.error) reject(msg.error);
        else resolve(msg.result);
      }
    });

    function esc(s) { return (s||'').replace(/&/g,'&amp;').replace(/"/g,'&quot;').replace(/</g,'&lt;'); }

    function formatQuery() {
      // Very basic formatting for demo purposes
      let q = document.getElementById('queryInput').value;
      if (!q) return;
      q = q.replace(/\\s+/g, ' ').replace(/\\s*([\\{\\}\\(\\):,])\\s*/g, '\$1');
      let out = '', indent = 0;
      for (let i=0; i<q.length; i++) {
        const c = q[i];
        if (c === '{' || c === '(') { out += ' ' + c + '\\n' + '  '.repeat(++indent); }
        else if (c === '}' || c === ')') { out += '\\n' + '  '.repeat(--indent) + c; }
        else if (c === ',') { out += ',\\n' + '  '.repeat(indent); }
        else { out += c; }
      }
      document.getElementById('queryInput').value = out.trim();
    }

    async function runQuery() {
      const url = document.getElementById('urlInput').value.trim();
      const query = document.getElementById('queryInput').value.trim();
      let variables = document.getElementById('varsInput').value.trim();

      if (!url || !query) { alert('Enter a URL and query first.'); return; }

      let parsedVars = {};
      if (variables) {
        try { parsedVars = JSON.parse(variables); }
        catch (e) { alert('Invalid JSON in variables: ' + e); return; }
      }

      const btn = document.getElementById('runBtn');
      btn.disabled = true;
      btn.innerHTML = '<span class="spinner" style="width:12px;height:12px;border-width:1.5px;display:inline-block;"></span> Running...';

      document.getElementById('resultPlaceholder').style.display = 'none';
      const resEl = document.getElementById('resultContent');
      resEl.style.display = 'block';
      resEl.style.color = 'var(--muted)';
      resEl.textContent = 'Executing query...';

      const startTime = Date.now();
      try {
        const result = await request('tools/call', {
          name: 'graphql-execute-query',
          arguments: { url, query, variables: parsedVars }
        });

        const elapsed = Date.now() - startTime;
        document.getElementById('execTime').textContent = elapsed + 'ms';

        const sc = result?.structuredContent;
        if (sc) {
          lastResponse = sc;
          const statusEl = document.getElementById('statusCode');
          statusEl.textContent = sc.status || 200;
          statusEl.style.color = (sc.status >= 400) ? 'var(--error)' : 'var(--success)';

          if (sc.hasErrors && sc.errors) {
            resEl.style.color = 'var(--error)';
            resEl.textContent = JSON.stringify(sc.errors, null, 2);
          } else {
            resEl.style.color = 'var(--text)';
            resEl.textContent = JSON.stringify(sc.data, null, 2);
          }
        } else {
          // Fallback: parse text response
          const text = result?.content?.[0]?.text || '';
          resEl.style.color = 'var(--text)';
          resEl.textContent = text;
        }
      } catch (e) {
        resEl.style.color = 'var(--error)';
        resEl.textContent = String(e);
      }

      btn.disabled = false;
      btn.innerHTML = '▶ Run Query';
    }

    async function initialize() {
      const statusEl = document.getElementById('connStatus');
      try {
        await request('ui/initialize', { protocolVersion: '2025-11-21', capabilities: {} });
        notify('ui/notifications/initialized', {});
        statusEl.textContent = '● Connected';
        statusEl.style.color = 'var(--success)';
      } catch (e) {
        statusEl.textContent = '○ Standalone';
        statusEl.style.color = 'var(--muted)';
      }
    }

    initialize();
  </script>
''',
  );
}
