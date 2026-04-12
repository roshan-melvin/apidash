/// Environment Manager panel — ported from the TS PoC.
library;

import 'dart:convert';
import '../styles.dart';

String buildEnvManagerPanel(Map<String, dynamic> environments) {
  return buildPanelHtml(
    title: 'APIDash · Environment Manager',
    panelStyles: envVarsStyles,
    body: '''
  <div class="header" style="border-bottom:none;">
    <span class="header-title">🌍 Environment Variables</span>
    <div style="margin-left:auto; display:flex; gap:6px; align-items:center;">
      <span class="statusbar" id="connStatus">Connecting…</span>
      <button class="btn-primary" onclick="saveEnvs()">
        💾 Save Changes
      </button>
    </div>
  </div>

  <div class="main" id="envContainer">
    <div id="envPlaceholder" style="padding:40px; text-align:center; color:var(--muted);">
      Loading environment data...
    </div>
  </div>

  <script>
    const pending = new Map();
    let nextId = 1;
    let envData = {}; // Format: { "scope-name": [{key, value, secret}], ... }

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

    function renderEnvs() {
      const el = document.getElementById('envContainer');
      const scopes = Object.keys(envData);
      
      if (scopes.length === 0) {
        el.innerHTML = '<div style="padding:40px; text-align:center; color:var(--muted);">No environments configured.</div>';
        return;
      }
      
      el.innerHTML = scopes.map(scope => \`
        <div class="env-panel">
          <div class="env-panel-header">
            <span class="env-scope-badge">\${esc(scope)}</span>
            <button class="btn-secondary" style="padding:2px 6px; font-size:9px;" onclick="addVar('\${scope}')">+ Add Variable</button>
          </div>
          <table class="env-table">
            <thead><tr><th>Variable Name</th><th>Value</th><th style="width:40px;"></th></tr></thead>
            <tbody>
              \${envData[scope].length === 0 ? '<tr><td colspan="3" style="text-align:center; color:var(--muted);">No variables defined</td></tr>' : ''}
              \${envData[scope].map((v, i) => \`
                <tr>
                  <td>
                    <input class="env-input" value="\${esc(v.key)}" oninput="envData['\${scope}'][parseInt('\${i}')].key=this.value" placeholder="BASE_URL" />
                  </td>
                  <td>
                    <div style="display:flex; gap:4px; align-items:center;">
                      <input class="env-input" type="\${v.secret ? 'password' : 'text'}" value="\${esc(v.value)}" oninput="envData['\${scope}'][parseInt('\${i}')].value=this.value" placeholder="https://..." />
                      <button class="env-secret-toggle" onclick="toggleSecret('\${scope}', \${i})">\${v.secret ? '👁' : '🙈'}</button>
                    </div>
                  </td>
                  <td>
                    <button class="btn-danger" style="padding:2px 6px; border:none; background:transparent;" onclick="delVar('\${scope}', \${i})">✕</button>
                  </td>
                </tr>
              \`).join('')}
            </tbody>
          </table>
        </div>
      \`).join('');
    }

    window.addVar = function(scope) {
      if (!envData[scope]) envData[scope] = [];
      envData[scope].push({key: '', value: '', secret: false});
      renderEnvs();
    };

    window.delVar = function(scope, idx) {
      envData[scope].splice(idx, 1);
      renderEnvs();
    };

    window.toggleSecret = function(scope, idx) {
      envData[scope][idx].secret = !envData[scope][idx].secret;
      renderEnvs();
    };

    async function saveEnvs() {
      // Build the JSON config representing the new environments
      const toSave = {};
      Object.keys(envData).forEach(scope => {
        toSave[scope] = {};
        envData[scope].forEach(v => {
          if (v.key) toSave[scope][v.key] = v.value;
        });
      });
      
      try {
        await request('tools/call', {
          name: 'manage-environment',
          arguments: { action: 'set', name: 'global', variables: toSave['global'] || {} }
        });
        
        document.querySelector('.btn-primary').textContent = '✅ Saved!';
        setTimeout(() => document.querySelector('.btn-primary').textContent = '💾 Save Changes', 2000);
      } catch (e) {
        alert("Failed to save: " + e);
      }
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
      
      // Inject environments logic
      if (window.__INITIAL_DATA__) {
        // Convert Map<String, dynamic> to our format
        Object.keys(window.__INITIAL_DATA__).forEach(k => {
          envData[k] = Object.entries(window.__INITIAL_DATA__[k] || {}).map(([key, val]) => ({
            key, value: String(val), secret: false
          }));
        });
        renderEnvs();
      } else {
        document.getElementById('envPlaceholder').textContent = 'No environment data available. Manage it by passing initial data.';
      }
    }

    // Convert initial injected JSON
    window.__INITIAL_DATA__ = ${jsonEncode(environments)};
    initialize();
  </script>
''',
  );
}
