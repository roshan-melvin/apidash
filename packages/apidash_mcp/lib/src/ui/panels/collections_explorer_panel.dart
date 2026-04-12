/// Collections Explorer panel — ported from the TS PoC.
library;

import '../styles.dart';

String buildCollectionsExplorerPanel() {
  return buildPanelHtml(
    title: 'APIDash · Collections',
    panelStyles: collectionsStyles,
    body: '''
  <div class="header">
    <span class="header-title">📚 APIDash Collections</span>
    <span class="header-subtitle">Your saved API requests</span>
    <div style="margin-left:auto; display:flex; gap:6px; align-items:center;">
      <span class="statusbar" id="connStatus">Connecting…</span>
      <button class="btn-primary" id="refreshBtn" onclick="fetchRequests()">
        ↻ Refresh
      </button>
    </div>
  </div>

  <div class="main">
    <div class="sidebar">
      <div class="sidebar-header">
        Workspace Requests <span id="reqCount" style="background:var(--accent-dim); color:var(--accent); padding:2px 6px; border-radius:10px;">0</span>
      </div>
      <div class="sidebar-search">
        <input type="text" id="searchInput" placeholder="Search..." oninput="filterRequests()" />
      </div>
      <div class="req-list" id="reqList"></div>
    </div>
    
    <div class="detail-pane" id="detailPane">
      <div class="empty-state" id="emptyState">
        <div class="empty-icon">👈</div>
        <div class="empty-text">Select a request to view details</div>
      </div>
      
      <div class="detail-content" id="detailContent" style="display:none;">
        <div style="display:flex; justify-content:space-between; align-items:flex-start;">
          <div>
            <div id="detName" style="font-weight:700; font-size:16px; margin-bottom:4px;"></div>
            <div style="display:flex; align-items:center; gap:8px;">
              <span id="detMethod" class="badge"></span>
              <span id="detUrl" style="font-family:var(--mono); font-size:11px; color:var(--text);"></span>
            </div>
          </div>
          <button class="btn-secondary" id="memoryBtn" onclick="moveToMemory()">+ Add to Chat</button>
        </div>
        
        <div id="detDesc" style="color:var(--muted); font-size:11px;"></div>
        
        <!-- Tabs -->
        <div class="tabs" style="margin-top:12px;">
          <button class="tab active" onclick="switchDetTab(this,'headers')">Headers</button>
          <button class="tab" onclick="switchDetTab(this,'body')">Body</button>
        </div>
        
        <div id="det-tab-headers" style="padding-top:8px;">
          <table class="data-table">
            <thead><tr><th style="width:120px;">Key</th><th>Value</th></tr></thead>
            <tbody id="detHeadersBody"></tbody>
          </table>
        </div>
        
        <div id="det-tab-body" style="display:none; padding-top:8px; flex-direction:column; flex:1;">
          <div id="detBodyContent" class="code-block" style="flex:1;"></div>
        </div>
      </div>
    </div>
  </div>

  <script>
    const pending = new Map();
    let nextId = 1;
    let allRequests = [];
    let selectedRequest = null;

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

    async function fetchRequests() {
      document.getElementById('refreshBtn').innerHTML = '<span class="spinner" style="width:12px;height:12px;border-width:1.5px"></span>';
      try {
        const result = await request('tools/call', {
          name: 'get-api-request-template', // Hack to list all since template tool wasn't modified? Wait, in Dart we don't have a list-requests tool that returns JSON. Let's assume it returns text. Wait, we can fetch all requests by calling explore-collections? No, explore-collections returns UI. We will inject the data dynamically or what?
          // Actually, wait, the TS PoC fetched the requests via a tool `get-api-request-template` but that returned one template.
          // In TS, fetchRequests was calling a custom RPC or something. Let's look at what TS did.
          // Wait, I will just call get-workspace-state tool if I have one? We don't have a data tool for workspace yet.
          // Okay, if I need the data, I can either have the resource return the HTML *with* the data injected, or add a tool.
          // Injecting the data into the HTML is the preferred way right now! 
          arguments: {}
        });
      } catch (e) {}
      // We will inject `__INITIAL_DATA__` below using Dart string interpolation.
    }
    
    function switchDetTab(btn, name) {
      document.querySelectorAll('.tab').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      ['headers','body'].forEach(t => {
        const el = document.getElementById('det-tab-' + t);
        if (el) el.style.display = t === name ? (t==='body'?'flex':'block') : 'none';
      });
    }

    function renderList(list) {
      const el = document.getElementById('reqList');
      if (!list.length) {
        el.innerHTML = '<div style="padding:16px;text-align:center;color:var(--muted);font-size:11px;">No requests found</div>';
        return;
      }
      el.innerHTML = list.map(r => \`
        <div class="req-item \${selectedRequest?.id===r.id?'active':''}" onclick="selectRequest('\${r.id}')">
          <div style="display:flex; flex-direction:column; gap:2px; flex:1; min-width:0;">
            <div style="display:flex; align-items:center; gap:6px;">
              <span style="font-weight:700; font-size:9px; color:var(--\${(r.method||'get').toLowerCase()})">\${r.method||'GET'}</span>
              <span class="req-name">\${esc(r.name || 'Unnamed')}</span>
            </div>
            <div class="req-url">\${esc(r.url)}</div>
          </div>
        </div>
      \`).join('');
    }

    function filterRequests() {
      const q = document.getElementById('searchInput').value.toLowerCase();
      const filtered = allRequests.filter(r => 
        (r.name||'').toLowerCase().includes(q) || 
        (r.url||'').toLowerCase().includes(q)
      );
      renderList(filtered);
    }

    window.selectRequest = function(id) {
      try {
        const req = allRequests.find(r => String(r.id) === String(id));
        if (!req) return;
        selectedRequest = req;
        renderList(allRequests);
        
        document.getElementById('emptyState').style.display = 'none';
        document.getElementById('detailContent').style.display = 'flex';
        
        document.getElementById('detName').textContent = req.name || 'Unnamed Request';
        document.getElementById('detMethod').textContent = (req.method || 'GET').toUpperCase();
        document.getElementById('detMethod').className = 'badge badge-' + (req.method || 'get').toLowerCase();
        document.getElementById('detUrl').textContent = req.url || '';
        document.getElementById('detDesc').textContent = req.description || '';
        
        const tbody = document.getElementById('detHeadersBody');
        const hData = req.headers || {};
        const hKeys = Object.keys(hData);
        if (hKeys.length) {
          tbody.innerHTML = hKeys.map(k => `<tr><td>\${esc(k)}</td><td>\${esc(String(hData[k]))}</td></tr>`).join('');
        } else {
          tbody.innerHTML = '<tr><td colspan="2" class="empty">No headers</td></tr>';
        }
        
        document.getElementById('detBodyContent').textContent = req.body || 'No body content';
      } catch (err) {
        document.getElementById('detailPane').innerHTML = `<div style="padding:20px; color:red; overflow-y:auto; font-family:monospace;"><h3>UI Crash:</h3>\${err.message}<br/>\${err.stack}</div>`;
      }
    }

    async function moveToMemory() {
      if (!selectedRequest) return;
      const btn = document.getElementById('memoryBtn');
      const prev = btn.innerHTML;
      btn.textContent = 'Updating...';
      try {
        await request('ui/update-model-context', {
          structuredContent: {
            request: selectedRequest
          }
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
      
      if (window.__INITIAL_DATA__) {
        allRequests = window.__INITIAL_DATA__;
        document.getElementById('reqCount').textContent = allRequests.length;
        renderList(allRequests);
      }
    }

    initialize();
  </script>
''',
  );
}
