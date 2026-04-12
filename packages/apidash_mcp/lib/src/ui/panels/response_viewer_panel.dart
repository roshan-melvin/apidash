/// Response Viewer panel — ported from the TS PoC.
library;

import '../styles.dart';

String buildResponseViewerPanel() {
  return buildPanelHtml(
    title: 'APIDash · Response Viewer',
    panelStyles: '',
    body: '''
  <div class="header">
    <span class="header-title">👀 APIDash Response Viewer</span>
    <span class="header-subtitle">Inspect the last HTTP response</span>
    <div style="margin-left:auto; display:flex; gap:6px; align-items:center;">
      <span class="statusbar" id="connStatus">Connecting…</span>
      <button class="btn-primary" id="refreshBtn" onclick="fetchLastResponse()">
        ↻ Refresh
      </button>
    </div>
  </div>

  <div class="main" style="padding: 12px; gap: 10px;">
    <div class="resp-status-bar" id="respMeta" style="display:none; border-radius: var(--radius-lg); border: 1px solid var(--border);">
      <span id="respStatus" style="font-weight:700; font-size:14px;"></span>
      <span class="response-meta-item" id="respTime"></span>
      <span class="response-meta-item" id="respSize"></span>
      <button class="btn-secondary" style="margin-left:auto;" onclick="submitToChat()">✓ Add Context to Chat</button>
      <button class="btn-secondary" onclick="copyResp()">📋 Copy</button>
    </div>

    <!-- Error/Empty State -->
    <div id="respPlaceholder" style="background:var(--surface); border:1px solid var(--border); border-radius:var(--radius-lg); padding:30px; text-align:center; color:var(--muted);">
      No valid response data found. Send a request first!
    </div>

    <!-- Tabs -->
    <div class="tabs" id="respTabs" style="display:none; margin-top:4px;">
      <button class="tab active" onclick="switchTab(this,'body')">Response Body</button>
      <button class="tab" onclick="switchTab(this,'headers')">Headers</button>
      <button class="tab" onclick="switchTab(this,'info')">Information</button>
    </div>

    <!-- Tab Contents -->
    <div id="tab-body" class="panel" style="display:none; flex:1; overflow:hidden; flex-direction:column; border-top-left-radius:0;">
      <div id="respBodyContent" class="resp-body" style="flex:1; max-height:100%; border:none;"></div>
    </div>

    <div id="tab-headers" class="panel" style="display:none; flex:1; overflow-y:auto; border-top-left-radius:0; padding:8px;">
      <div id="respHeadersContent"></div>
    </div>

    <div id="tab-info" class="panel" style="display:none; flex:1; overflow-y:auto; border-top-left-radius:0; padding:12px;">
      <div id="respInfoContent"></div>
    </div>
  </div>

  <script>
    const pending = new Map();
    let nextId = 1;
    let currentData = null;

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

    function switchTab(btn, name) {
      document.querySelectorAll('.tab').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      ['body','headers','info'].forEach(t => {
        const el = document.getElementById('tab-' + t);
        if (el) el.style.display = t === name ? 'flex' : 'none';
      });
    }

    function esc(s) { return (s||'').replace(/&/g,'&amp;').replace(/"/g,'&quot;').replace(/</g,'&lt;'); }

    function copyResp() {
      if (!currentData || !currentData.body) return;
      const t = typeof currentData.body === 'string' ? currentData.body : JSON.stringify(currentData.body, null, 2);
      navigator.clipboard?.writeText(t);
      const btn = document.querySelector('.btn-secondary:last-child');
      const old = btn.textContent;
      btn.textContent = '📋 Copied!';
      setTimeout(() => btn.textContent = old, 2000);
    }

    async function submitToChat() {
      if (!currentData) return;
      try {
        await request('ui/update-model-context', {
          structuredContent: {
            notification: "User wants to analyze this response",
            response: currentData,
          }
        });
      } catch (e) { console.error('Failed to update context', e); }
    }

    async function fetchLastResponse() {
      document.getElementById('refreshBtn').innerHTML = '<span class="spinner" style="width:12px;height:12px;border-width:1.5px"></span>';
      try {
        const data = await request('tools/call', {
          name: 'get-last-response',
          arguments: {}
        });

        // Parse state
        const sc = data?.structuredContent || {};
        const resp = sc.lastResponse || {};

        if (!resp || Object.keys(resp).length === 0) {
           document.getElementById('respPlaceholder').style.display = '';
           document.getElementById('respMeta').style.display = 'none';
           document.getElementById('respTabs').style.display = 'none';
           ['body','headers','info'].forEach(t => document.getElementById('tab-' + t).style.display = 'none');
           return;
        }

        currentData = resp;
        const status = resp.responseStatus || resp.status || 0;
        const duration = resp.time || resp.duration || 0;
        const bodyStr = typeof resp.body === 'string' ? resp.body : JSON.stringify(resp.body, null, 2);
        const size = bodyStr ? (new Blob([bodyStr]).size / 1024).toFixed(1) + ' KB' : '—';
        
        document.getElementById('respPlaceholder').style.display = 'none';
        document.getElementById('respMeta').style.display = 'flex';
        document.getElementById('respTabs').style.display = 'flex';
        switchTab(document.querySelector('.tab'), 'body');

        const cls = status >= 500 ? 'status-5xx' : status >= 400 ? 'status-4xx' : status >= 300 ? 'status-3xx' : 'status-2xx';
        document.getElementById('respStatus').innerHTML = `<span class="\${cls}">\${status}</span>`;
        document.getElementById('respTime').textContent = duration + 'ms';
        document.getElementById('respSize').textContent = size;

        document.getElementById('respBodyContent').textContent = bodyStr || '(empty)';

        const headersEl = document.getElementById('respHeadersContent');
        if (resp.headers) {
          headersEl.innerHTML = '<div class="headers-grid">' +
            Object.entries(resp.headers).map(([k,v]) =>
              `<div class="hdr-key">\${esc(k)}</div><div class="hdr-val">\${esc(String(v))}</div>`
            ).join('') + '</div>';
        } else {
          headersEl.innerHTML = '<div class="empty-state">No headers</div>';
        }

        const infoEl = document.getElementById('respInfoContent');
        infoEl.innerHTML = `
          <div style="display:flex; flex-direction:column; gap:8px;">
             <div><span class="section-label">Request Metrics</span></div>
             <div class="inline-row">
               <div><span style="color:var(--muted)">Network Time:</span> \${duration}ms</div>
               <div><span style="color:var(--muted)">Response Size:</span> \${size}</div>
             </div>
          </div>
        `;

      } catch (e) {
        console.error("Failed to fetch response:", e);
      }
      document.getElementById('refreshBtn').innerHTML = '↻ Refresh';
    }

    async function initialize() {
      const statusEl = document.getElementById('connStatus');
      try {
        await request('ui/initialize', { protocolVersion: '2025-11-21', capabilities: {}, clientInfo: { name: 'apidash-resp-viewer', version: '1.0.0' } });
        notify('ui/notifications/initialized', {});
        statusEl.textContent = '● Connected';
        statusEl.style.color = 'var(--success)';
        fetchLastResponse();
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
