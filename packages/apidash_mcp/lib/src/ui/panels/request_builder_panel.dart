/// Interactive Request Builder panel — ported from the TS PoC.
///
/// This generates a self-contained HTML page with inline JavaScript that
/// communicates with VS Code Copilot via `window.parent.postMessage`.
library;

import '../styles.dart';

/// Builds the full interactive Request Builder HTML panel.
String buildRequestBuilderPanel() {
  const methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];
  final methodOptions = methods
      .map((m) => '<option value="$m">$m</option>')
      .join('\n        ');

  return buildPanelHtml(
    title: 'APIDash · Request Builder',
    panelStyles: requestBuilderStyles,
    body: '''
  <div class="header">
    <span class="header-title">🚀 APIDash Request Builder</span>
    <span class="header-subtitle">Build and test HTTP requests</span>
    <div style="margin-left:auto; display:flex; gap:6px; align-items:center;">
      <span class="statusbar" id="connStatus">Connecting…</span>
    </div>
  </div>

  <div class="main">
    <!-- URL Row -->
    <div class="url-row">
      <select id="methodSelect" class="method-select" onchange="onMethodChange()">
        $methodOptions
      </select>
      <input type="text" id="urlInput" class="url-input"
        placeholder="https://api.example.com/endpoint"
      />
      <button id="sendBtn" class="send-btn" onclick="sendRequest()">
        <span id="sendIcon">▶</span> Send
      </button>
    </div>

    <!-- Request / Response Panes -->
    <div class="panes">
      <!-- Request Pane -->
      <div class="pane">
        <div class="tabs">
          <button class="tab active" onclick="switchReqTab(this,'params')">Params</button>
          <button class="tab" onclick="switchReqTab(this,'headers')">Headers</button>
          <button class="tab" onclick="switchReqTab(this,'body')">Body</button>
          <button class="tab" onclick="switchReqTab(this,'auth')">Auth</button>
        </div>

        <!-- Params -->
        <div id="tab-params" class="pane-content">
          <div id="paramsRows"></div>
          <button class="add-row-btn" onclick="addParam()">+ Add Parameter</button>
        </div>

        <!-- Headers -->
        <div id="tab-headers" class="pane-content" style="display:none;">
          <div id="headersRows"></div>
          <button class="add-row-btn" onclick="addHeader()">+ Add Header</button>
        </div>

        <!-- Body -->
        <div id="tab-body" class="pane-content" style="display:none; padding:0; flex-direction:column;">
          <div class="body-type-tabs">
            <button class="body-tab active" onclick="switchBodyType(this,'none')">None</button>
            <button class="body-tab" onclick="switchBodyType(this,'json')">JSON</button>
            <button class="body-tab" onclick="switchBodyType(this,'text')">Text</button>
            <button class="body-tab" onclick="switchBodyType(this,'form')">Form</button>
          </div>
          <div id="bodyNone" style="padding:12px; color:var(--muted); font-size:11px;">No body</div>
          <textarea id="bodyJson" class="body-textarea" style="display:none;"
            placeholder='{ "key": "value" }'></textarea>
          <textarea id="bodyText" class="body-textarea" style="display:none;"
            placeholder="Plain text body..."></textarea>
          <div id="bodyForm" style="display:none; padding:8px; flex:1; overflow-y:auto;">
            <div id="formRows"></div>
            <button class="add-row-btn" onclick="addFormField()">+ Add Field</button>
          </div>
        </div>

        <!-- Auth -->
        <div id="tab-auth" class="pane-content" style="display:none;">
          <div class="field-row" style="margin-bottom:10px;">
            <label>Auth Type</label>
            <select id="authType" class="field-select" style="width:100%; padding:5px;" onchange="onAuthTypeChange()">
              <option value="none">No Auth</option>
              <option value="bearer">Bearer Token</option>
              <option value="basic">Basic Auth</option>
              <option value="apikey">API Key</option>
            </select>
          </div>
          <div id="authNone" style="color:var(--muted); font-size:11px;">No authentication</div>
          <div id="authBearer" style="display:none;">
            <div class="field-row">
              <label>Token</label>
              <input type="text" id="bearerToken" class="field-input" style="width:100%; padding:5px;" placeholder="Enter bearer token..." />
            </div>
          </div>
          <div id="authBasic" style="display:none;">
            <div class="field-row">
              <label>Username</label>
              <input type="text" id="basicUser" class="field-input" style="width:100%; padding:5px;" placeholder="username" />
            </div>
            <div class="field-row" style="margin-top:6px;">
              <label>Password</label>
              <input type="password" id="basicPass" class="field-input" style="width:100%; padding:5px;" placeholder="password" />
            </div>
          </div>
          <div id="authApiKey" style="display:none;">
            <div class="field-row">
              <label>Key Name</label>
              <input type="text" id="apiKeyName" class="field-input" style="width:100%; padding:5px; margin-bottom:6px;" placeholder="X-API-Key" />
            </div>
            <div class="field-row" style="margin-top:6px;">
              <label>Key Value</label>
              <input type="text" id="apiKeyValue" class="field-input" style="width:100%; padding:5px;" placeholder="your-api-key" />
            </div>
          </div>
        </div>
      </div>

      <!-- Response Pane -->
      <div class="pane">
        <div class="tabs">
          <button class="tab active" onclick="switchRespTab(this,'body')">Body</button>
          <button class="tab" onclick="switchRespTab(this,'headers')">Headers</button>
          <button class="tab" onclick="switchRespTab(this,'info')">Info</button>
        </div>

        <div id="respMeta" class="response-meta" style="display:none;">
          <span id="respStatus" class="response-status"></span>
          <span class="response-meta-item" id="respTime"></span>
          <span class="response-meta-item" id="respSize"></span>
        </div>

        <div id="resp-tab-body" class="pane-content">
          <div id="respPlaceholder" style="color:var(--muted); font-size:11px; padding:8px;">
            Send a request to see the response
          </div>
          <div id="respBodyContent" class="response-body" style="display:none;"></div>
        </div>
        <div id="resp-tab-headers" class="pane-content" style="display:none;">
          <div id="respHeadersContent"></div>
        </div>
        <div id="resp-tab-info" class="pane-content" style="display:none;">
          <div id="respInfoContent"></div>
        </div>
      </div>
    </div>
  </div>

  <div class="footer">
    <button class="btn-secondary" onclick="resetAll()">↺ Reset</button>
    <button class="btn-secondary" onclick="copyAsCurl()">📋 Copy as cURL</button>
    <div style="margin-left:auto; display:flex; gap:6px; align-items:center;">
      <span class="statusbar" id="reqStatus"></span>
      <button class="btn-primary" id="submitBtn" onclick="submitToChat()" disabled>
        ✓ Add to Chat
      </button>
    </div>
  </div>

  <script>
    // ------ MCP Communication ------
    const pending = new Map();
    let nextId = 1;
    let lastResponse = null;
    let currentBodyType = 'none';
    let currentAuthType = 'none';

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
      if (msg.method === 'ui/setTheme') {
        const theme = msg.params?.theme || 'dark';
        document.body.className = theme;
      }
      // Handle preload from Collections Explorer or model context
      if (msg.method === 'ui/model-context-updated') {
        const preload = msg.params?.structuredContent?.preload;
        if (preload) preloadRequest(preload);
      }
    });

    // ------ UI State ------
    let paramRows = [];
    let headerRows = [];
    let formRows = [];
    let reqTabActive = 'params';
    let respTabActive = 'body';

    function switchReqTab(btn, name) {
      document.querySelectorAll('.tabs').forEach((t, i) => { if (i === 0) t.querySelectorAll('.tab').forEach(b => b.classList.remove('active')); });
      btn.classList.add('active');
      ['params','headers','body','auth'].forEach(t => {
        document.getElementById('tab-' + t).style.display = t === name ? '' : 'none';
      });
      reqTabActive = name;
    }

    function switchRespTab(btn, name) {
      document.querySelectorAll('.tabs')[1]?.querySelectorAll('.tab').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      ['body','headers','info'].forEach(t => {
        const el = document.getElementById('resp-tab-' + t);
        if (el) el.style.display = t === name ? '' : 'none';
      });
      respTabActive = name;
    }

    function switchBodyType(btn, type) {
      document.querySelectorAll('.body-tab').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentBodyType = type;
      ['none','json','text','form'].forEach(t => {
        document.getElementById('body' + t.charAt(0).toUpperCase() + t.slice(1)).style.display = t === type ? '' : 'none';
      });
    }

    function onAuthTypeChange() {
      currentAuthType = document.getElementById('authType').value;
      ['None','Bearer','Basic','ApiKey'].forEach(t => {
        const el = document.getElementById('auth' + t);
        if (el) el.style.display = t.toLowerCase() === currentAuthType ? '' : 'none';
      });
    }

    function onMethodChange() {
      const method = document.getElementById('methodSelect').value;
      const hasBody = ['POST','PUT','PATCH'].includes(method);
    }

    // Pre-fill form from a saved request (called by polling preload state)
    function preloadRequest(reqArg) {
      if (!reqArg) return;
      // Support both flat object and nested { request: { ... } } wrapper
      const req = (reqArg.request && typeof reqArg.request === 'object') ? reqArg.request : reqArg;

      // Set method — use a loop so it works regardless of browser select quirks
      if (req.method) {
        const sel = document.getElementById('methodSelect');
        const target = req.method.toUpperCase();
        for (let i = 0; i < sel.options.length; i++) {
          if (sel.options[i].value === target) { sel.selectedIndex = i; break; }
        }
        onMethodChange();
      }

      // Set URL
      if (req.url) {
        document.getElementById('urlInput').value = req.url;
      }

      // Pre-fill headers
      const hdrs = req.headers || {};
      headerRows = Object.entries(hdrs).map(([k, v]) => ({ key: k, value: String(v) }));
      renderHeaderRows();

      // Pre-fill body and switch to appropriate tab
      if (req.body) {
        let isJson = false;
        try { JSON.parse(req.body); isJson = true; } catch (_) {}
        if (isJson) {
          switchBodyType(document.querySelector('.body-tab:nth-child(2)'), 'json');
          document.getElementById('bodyJson').value = req.body;
        } else {
          switchBodyType(document.querySelector('.body-tab:nth-child(3)'), 'text');
          document.getElementById('bodyText').value = req.body;
        }
        // Switch the request pane to the Body tab so the user sees it
        const bodyTabBtn = document.querySelector('.tabs .tab:nth-child(3)');
        if (bodyTabBtn) switchReqTab(bodyTabBtn, 'body');
      }

      // Enable Submit button
      document.getElementById('submitBtn').disabled = false;
      setStatus('\u2705 Pre-filled: ' + (req.name || req.url || 'request'), 'success');
      setTimeout(() => setStatus('', ''), 4000);
    }

    // ------ Param / Header / Form management ------
    function renderParamRows() {
      const container = document.getElementById('paramsRows');
      container.innerHTML = paramRows.map((row, i) => `
        <div class="param-row">
          <input class="param-input" placeholder="Key" value="\${esc(row.key)}" oninput="paramRows[\${i}].key=this.value" />
          <input class="param-input" placeholder="Value" value="\${esc(row.value)}" oninput="paramRows[\${i}].value=this.value" />
          <button class="remove-btn" onclick="delParam(\${i})">✕</button>
        </div>
      `).join('');
    }
    function addParam() { paramRows.push({key:'',value:''}); renderParamRows(); }
    function delParam(i) { paramRows.splice(i,1); renderParamRows(); }

    function renderHeaderRows() {
      const container = document.getElementById('headersRows');
      container.innerHTML = headerRows.map((row, i) => `
        <div class="param-row">
          <input class="param-input" placeholder="Header Name" value="\${esc(row.key)}" oninput="headerRows[\${i}].key=this.value" />
          <input class="param-input" placeholder="Value" value="\${esc(row.value)}" oninput="headerRows[\${i}].value=this.value" />
          <button class="remove-btn" onclick="delHeader(\${i})">✕</button>
        </div>
      `).join('');
    }
    function addHeader() { headerRows.push({key:'',value:''}); renderHeaderRows(); }
    function delHeader(i) { headerRows.splice(i,1); renderHeaderRows(); }

    function renderFormRows() {
      const container = document.getElementById('formRows');
      container.innerHTML = formRows.map((row, i) => `
        <div class="param-row">
          <input class="param-input" placeholder="Field Name" value="\${esc(row.key)}" oninput="formRows[\${i}].key=this.value" />
          <input class="param-input" placeholder="Value" value="\${esc(row.value)}" oninput="formRows[\${i}].value=this.value" />
          <button class="remove-btn" onclick="delFormField(\${i})">✕</button>
        </div>
      `).join('');
    }
    function addFormField() { formRows.push({key:'',value:''}); renderFormRows(); }
    function delFormField(i) { formRows.splice(i,1); renderFormRows(); }

    function esc(s) { return (s||'').replace(/&/g,'&amp;').replace(/"/g,'&quot;').replace(/</g,'&lt;'); }

    // ------ Build Request ------
    function buildRequest() {
      const method = document.getElementById('methodSelect').value;
      let url = document.getElementById('urlInput').value.trim();

      const validParams = paramRows.filter(r => r.key);
      if (validParams.length) {
        const sep = url.includes('?') ? '&' : '?';
        url += sep + validParams.map(r => encodeURIComponent(r.key) + '=' + encodeURIComponent(r.value)).join('&');
      }

      const headers = {};
      headerRows.filter(r => r.key).forEach(r => { headers[r.key] = r.value; });

      if (currentAuthType === 'bearer') {
        const token = document.getElementById('bearerToken').value;
        if (token) headers['Authorization'] = 'Bearer ' + token;
      } else if (currentAuthType === 'basic') {
        const u = document.getElementById('basicUser').value;
        const p = document.getElementById('basicPass').value;
        if (u || p) headers['Authorization'] = 'Basic ' + btoa(u + ':' + p);
      } else if (currentAuthType === 'apikey') {
        const kn = document.getElementById('apiKeyName').value;
        const kv = document.getElementById('apiKeyValue').value;
        if (kn) headers[kn] = kv;
      }

      let body = undefined;
      if (currentBodyType === 'json') {
        body = document.getElementById('bodyJson').value;
        if (body && !headers['Content-Type']) headers['Content-Type'] = 'application/json';
      } else if (currentBodyType === 'text') {
        body = document.getElementById('bodyText').value;
        if (body && !headers['Content-Type']) headers['Content-Type'] = 'text/plain';
      } else if (currentBodyType === 'form') {
        const validForm = formRows.filter(r => r.key);
        if (validForm.length) {
          body = validForm.map(r => encodeURIComponent(r.key) + '=' + encodeURIComponent(r.value)).join('&');
          headers['Content-Type'] = 'application/x-www-form-urlencoded';
        }
      }

      return { method, url, headers, body };
    }

    // ------ Send Request ------
    async function sendRequest() {
      const { method, url, headers, body } = buildRequest();
      if (!url) { setStatus('⚠️ Enter a URL', 'warning'); return; }

      const btn = document.getElementById('sendBtn');
      btn.disabled = true;
      btn.innerHTML = '<span class="spinner"></span> Sending…';
      setStatus('', '');
      document.getElementById('submitBtn').disabled = true;
      lastResponse = null;

      const startTime = Date.now();
      try {
        const result = await request('tools/call', {
          name: 'http-send-request',
          arguments: { method, url, headers, body }
        });

        const elapsed = Date.now() - startTime;
        const sc = result?.structuredContent;
        if (sc) {
          lastResponse = sc;
          showResponse(sc, elapsed);
          document.getElementById('submitBtn').disabled = false;
          setStatus('✅ ' + sc.status + ' ' + sc.statusText, 'success');

          request('ui/update-model-context', {
            structuredContent: {
              request: { method, url, headers, body },
              response: lastResponse,
            }
          }).catch(console.error);

        } else {
          showRawResponse(result, elapsed);
        }
      } catch (e) {
        showError(e);
        setStatus('❌ Request failed', 'error');
      }

      btn.disabled = false;
      btn.innerHTML = '▶ Send';
    }

    function showResponse(sc, elapsed) {
      const meta = document.getElementById('respMeta');
      meta.style.display = 'flex';
      const statusEl = document.getElementById('respStatus');
      const cls = sc.status >= 500 ? 'status-5xx' : sc.status >= 400 ? 'status-4xx' : sc.status >= 300 ? 'status-3xx' : 'status-2xx';
      statusEl.innerHTML = `<span class="\${cls}">\${sc.status} \${sc.statusText}</span>`;
      document.getElementById('respTime').textContent = elapsed + 'ms';
      document.getElementById('respSize').textContent = sc.body ? (new Blob([sc.body]).size / 1024).toFixed(1) + ' KB' : '—';

      document.getElementById('respPlaceholder').style.display = 'none';
      const bodyEl = document.getElementById('respBodyContent');
      bodyEl.style.display = '';
      bodyEl.textContent = typeof sc.body === 'object' ? JSON.stringify(sc.body, null, 2) : sc.body || '(empty)';

      const headersEl = document.getElementById('respHeadersContent');
      if (sc.headers) {
        headersEl.innerHTML = '<div class="headers-grid">' +
          Object.entries(sc.headers).map(([k,v]) =>
            `<div class="hdr-key">\${esc(k)}</div><div class="hdr-val">\${esc(String(v))}</div>`
          ).join('') + '</div>';
      }

      const infoEl = document.getElementById('respInfoContent');
      infoEl.innerHTML = `
        <div style="display:flex; flex-direction:column; gap:6px; font-size:11px;">
          <div><span style="color:var(--muted)">Method:</span> \${sc.method || '—'}</div>
          <div><span style="color:var(--muted)">URL:</span> <span style="font-family:var(--mono)">\${esc(sc.url || '')}</span></div>
          <div><span style="color:var(--muted)">Status:</span> \${sc.status} \${sc.statusText}</div>
          <div><span style="color:var(--muted)">Duration:</span> \${elapsed}ms</div>
          <div><span style="color:var(--muted)">Body Size:</span> \${sc.body ? (new Blob([sc.body]).size / 1024).toFixed(1) + ' KB' : '0 KB'}</div>
        </div>
      `;
    }

    function showRawResponse(result, elapsed) {
      document.getElementById('respMeta').style.display = 'none';
      document.getElementById('respPlaceholder').style.display = 'none';
      const bodyEl = document.getElementById('respBodyContent');
      bodyEl.style.display = '';
      bodyEl.textContent = JSON.stringify(result, null, 2);
    }

    function showError(e) {
      document.getElementById('respMeta').style.display = 'none';
      document.getElementById('respPlaceholder').style.display = 'none';
      const bodyEl = document.getElementById('respBodyContent');
      bodyEl.style.display = '';
      bodyEl.style.color = 'var(--error)';
      bodyEl.textContent = 'Error: ' + (e?.message || String(e));
    }

    // ------ Submit to Chat ------
    async function submitToChat() {
      if (!lastResponse) return;
      setStatus('Updating context…', '');
      try {
        await request('ui/update-model-context', {
          structuredContent: {
            request: buildRequest(),
            response: lastResponse,
          }
        });
        setStatus('✅ Added to chat', 'success');
        document.getElementById('submitBtn').disabled = true;
      } catch (e) {
        setStatus('❌ ' + (e?.message || 'Failed'), 'error');
      }
    }

    // ------ Helpers ------
    function setStatus(msg, type) {
      const el = document.getElementById('reqStatus');
      el.textContent = msg;
      el.className = 'statusbar' + (type ? ' ' + type : '');
    }

    function resetAll() {
      document.getElementById('urlInput').value = '';
      document.getElementById('methodSelect').value = 'GET';
      paramRows = []; renderParamRows();
      headerRows = []; renderHeaderRows();
      formRows = []; renderFormRows();
      document.getElementById('bodyJson').value = '';
      document.getElementById('bodyText').value = '';
      document.getElementById('bearerToken').value = '';
      document.getElementById('basicUser').value = '';
      document.getElementById('basicPass').value = '';
      document.getElementById('apiKeyName').value = '';
      document.getElementById('apiKeyValue').value = '';
      document.getElementById('respPlaceholder').style.display = '';
      document.getElementById('respBodyContent').style.display = 'none';
      document.getElementById('respBodyContent').style.color = '';
      document.getElementById('respMeta').style.display = 'none';
      document.getElementById('submitBtn').disabled = true;
      lastResponse = null;
      setStatus('', '');
    }

    function copyAsCurl() {
      const { method, url, headers, body } = buildRequest();
      const parts = [`curl -X \${method} '\${url}'`];
      Object.entries(headers).forEach(([k,v]) => parts.push(`  -H '\${k}: \${v}'`));
      if (body) parts.push(`  --data '\${body}'`);
      navigator.clipboard?.writeText(parts.join(' \\\\\\n')).then(() => setStatus('📋 Copied!', 'success'));
    }

    // ------ Initialize ------
    async function initialize() {
      const statusEl = document.getElementById('connStatus');
      try {
        await request('ui/initialize', {
          protocolVersion: '2025-11-21',
          capabilities: {},
          clientInfo: { name: 'apidash-request-builder', version: '1.0.0' }
        });
        notify('ui/notifications/initialized', {});
        statusEl.textContent = '● Connected';
        statusEl.style.color = 'var(--success)';
        // Apply preload injected by server in HTML (fresh fetch path)
        if (window.__PRELOAD_REQUEST__) {
          preloadRequest(window.__PRELOAD_REQUEST__);
          window.__PRELOAD_REQUEST__ = null;
        }
      } catch (e) {
        statusEl.textContent = '○ Standalone';
        statusEl.style.color = 'var(--muted)';
      }
    }

    // Poll server every 2s for a pending preload — clears itself once consumed.
    // This is needed because VS Code keeps the panel alive across tool calls,
    // so initialize() only runs once on first load.
    async function pollPreload() {
      try {
        const res = await request('tools/call', {
          name: 'get-preload-state',
          arguments: { panel: 'request-builder' }
        });
        const preload = res?.structuredContent?.preload;
        if (preload) preloadRequest(preload);
      } catch(_) {}
    }

    initialize();
    // First poll immediately (catches preload set before panel was ready)
    pollPreload();
    // Then keep polling every 2s for future tool calls
    setInterval(pollPreload, 2000);
    notify('ui/notifications/size-changed', { width: document.body.scrollWidth, height: 520 });
  </script>
''',
  );
}
