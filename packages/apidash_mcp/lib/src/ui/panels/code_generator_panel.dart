/// Code Generator panel — ported from the TS PoC.
library;

import '../styles.dart';

String buildCodeGeneratorPanel(List<String> supportedGenerators) {
  final langOptions = supportedGenerators.map((g) => '<option value="$g">$g</option>').join('');

  return buildPanelHtml(
    title: 'APIDash · Code Generator',
    panelStyles: codegenStyles,
    body: '''
  <div class="header">
    <span class="header-title">💻 Code Generator</span>
    <span class="header-subtitle">Generate HTTP request snippets</span>
    <div style="margin-left:auto; display:flex; gap:6px; align-items:center;">
      <span class="statusbar" id="connStatus">Connecting…</span>
      <button id="generateBtn" class="btn-primary" onclick="generate()">
        ▶ Generate
      </button>
    </div>
  </div>

  <div class="main" style="padding: 12px; gap: 10px;">
    <div class="card" style="padding: 12px;">
      <p style="font-size: 11px; margin-bottom: 8px;">Select a request & language to generate code:</p>
      
      <div style="display:flex; gap:8px;">
        <select id="requestSelect" style="flex:2; padding: 6px 10px;" onchange="updateAvailableLanguages()">
          <option value="">No requests available</option>
        </select>
        <select id="langInput" style="flex:1; padding: 6px 10px;">
          $langOptions
        </select>
      </div>
    </div>

    <!-- Result -->
    <div class="code-output" id="outputPanel" style="display:flex; flex-direction:column; flex:1; min-height:200px;">
      <div class="code-toolbar">
        <span id="genLang" style="font-weight:600; text-transform:uppercase; font-size:10px;">Language</span>
        <div style="display:flex; gap:6px;">
          <button class="btn-secondary" id="memoryBtn" onclick="moveToMemory()" style="padding:2px 8px; font-size:10px;">+ Add to Chat</button>
          <button class="btn-secondary" onclick="copyCode()" style="padding:2px 8px; font-size:10px;">📋 Copy</button>
        </div>
      </div>
      <div id="codePlaceholder" style="padding:40px; text-align:center; color:var(--muted);">
        Enter a target language and click Generate
      </div>
      <div id="codeContent" class="code-content" style="display:none; flex:1;"></div>
    </div>
  </div>

  <script>
    const pending = new Map();
    let nextId = 1;
    let currentCode = null;
    let requestsData = [];

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

    // We use window.__INITIAL_CONTEXT__ provided by the resource injector
    // to determine which request we are generating code for.

    async function generate() {
      const gen = document.getElementById('langInput').value.trim();
      if (!gen) return;

      const selIdx = document.getElementById('requestSelect').value;
      const ctx = (requestsData && requestsData[selIdx]) ? requestsData[selIdx] : (requestsData[0] || {});
      const method = ctx.method || 'GET';
      const url = ctx.url || 'https://jsonplaceholder.typicode.com/posts/1';

      document.getElementById('codePlaceholder').style.display = 'none';
      const out = document.getElementById('codeContent');
      out.style.display = 'block';
      out.innerHTML = '<span class="spinner" style="display:inline-block;"></span> Generating...';
      document.getElementById('genLang').textContent = gen.toUpperCase();

      try {
        const result = await request('tools/call', {
          name: 'generate-code-snippet',
          // Pass the complete request ctx so Headers and Body are preserved if APIDash CLI updates to use them
          arguments: { generator: gen, method, url, requestBody: ctx.body }
        });

        const sc = result?.structuredContent;
        if (sc && sc.code) {
          currentCode = sc.code;
          out.textContent = sc.code;
          document.getElementById('genLang').textContent = (sc.language || gen).toUpperCase();
        } else {
          out.textContent = JSON.stringify(result, null, 2);
        }
      } catch (e) {
        out.textContent = String(e);
        out.style.color = 'var(--error)';
      }
    }

    function copyCode() {
      if (!currentCode) return;
      navigator.clipboard?.writeText(currentCode);
    }

    async function moveToMemory() {
      if (!currentCode) return;
      const selIdx = document.getElementById('requestSelect').value;
      const ctx = (requestsData && requestsData[selIdx]) ? requestsData[selIdx] : {};
      const payload = {
        request: ctx,
        generatedCode: currentCode,
        language: document.getElementById('langInput').value
      };
      
      const btn = document.getElementById('memoryBtn');
      const prev = btn.innerHTML;
      btn.textContent = 'Updating...';
      try {
        await request('ui/update-model-context', {
          structuredContent: payload
        });
        btn.innerHTML = '✓ Added to Chat';
      } catch(e) {
        console.error(e);
        btn.textContent = '❌ Failed';
      }
      setTimeout(() => btn.innerHTML = prev, 3000);
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

      // Populate dropdown
      requestsData = window.__INITIAL_CONTEXT__ || [];
      const sel = document.getElementById('requestSelect');
      if (requestsData.length > 0) {
        sel.innerHTML = requestsData.map((r, i) => {
          const method = (r.method || 'GET').toUpperCase();
          const name = r.name || r.url || 'Unnamed Request';
          return `<option value="\${i}">[\${method}] \${name}</option>`;
        }).join('');
      }

      // Disable UI generating if it's a non-HTTP request lacking a valid method
      window.updateAvailableLanguages = function() {
        const selIdx = document.getElementById('requestSelect').value;
        const ctx = (requestsData && requestsData[selIdx]) ? requestsData[selIdx] : null;
        const langSel = document.getElementById('langInput');
        const generateBtn = document.getElementById('generateBtn');
        const isValid = ctx && ctx.method && ctx.url;
        if (isValid) {
          langSel.disabled = false;
          generateBtn.disabled = false;
        } else {
          langSel.disabled = true;
          generateBtn.disabled = true;
        }
      };

      // Select last item by default
      if (requestsData.length > 0) {
        sel.value = String(requestsData.length - 1);
        updateAvailableLanguages();
      }

      // Ask server if any request was pre-selected (bypasses VS Code HTML cache)
      // Check window injected value first
      let preloadId = window.__PRELOAD_REQUEST_ID__;
      window.__PRELOAD_REQUEST_ID__ = null; // consume
      
      if (!preloadId) {
        try {
          const preloadResult = await request('tools/call', {
            name: 'get-preload-state',
            arguments: { panel: 'code-generator' }
          });
          preloadId = preloadResult?.structuredContent?.preload?.id;
        } catch(_) { /* no preload */ }
      }

      if (preloadId) {
        const idx = requestsData.findIndex(r => String(r.id) === String(preloadId));
        if (idx >= 0) {
          sel.value = String(idx);
          updateAvailableLanguages();
        }
      }
    }

    // Poll server every 2s for a pending preload (VS Code keeps panel alive, so initialize() only runs once)
    async function pollPreload() {
      const sel = document.getElementById('requestSelect');
      try {
        const res = await request('tools/call', {
          name: 'get-preload-state',
          arguments: { panel: 'code-generator' }
        });
        const preload = res?.structuredContent?.preload;
        if (preload && preload.id) {
          const idx = requestsData.findIndex(r => String(r.id) === String(preload.id));
          if (idx >= 0) {
            sel.value = String(idx);
            updateAvailableLanguages();
          }
        }
      } catch(_) {}
    }

    initialize();
    pollPreload();
    setInterval(pollPreload, 2000);
  </script>
''',
  );
}
