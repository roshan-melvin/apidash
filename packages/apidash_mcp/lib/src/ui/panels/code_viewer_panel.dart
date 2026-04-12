/// Code Viewer / Resource Info panel — ported from the TS PoC.
library;

import '../styles.dart';

String buildCodeViewerPanel() {
  return buildPanelHtml(
    title: 'APIDash · MCP Reference',
    panelStyles: '',
    body: '''
  <div class="header">
    <span class="header-title">📖 MCP Reference</span>
    <span class="header-subtitle">Available Tools and Capabilities</span>
    <div style="margin-left:auto; display:flex; gap:6px; align-items:center;">
      <span class="statusbar" id="connStatus">Connecting…</span>
    </div>
  </div>

  <div class="main" style="padding: 12px; gap: 10px; overflow-y:auto; overflow-x:hidden;">
    <div class="panel">
      <div class="panel-header">Interactive UI Tools</div>
      <table class="data-table">
        <thead>
          <tr><th>Tool Name</th><th>Description</th></tr>
        </thead>
        <tbody>
          <tr><td style="font-weight:bold;">request-builder</td><td>Opens the interactive API testing panel</td></tr>
          <tr><td style="font-weight:bold;">view-response</td><td>Displays the last HTTP response received</td></tr>
          <tr><td style="font-weight:bold;">explore-collections</td><td>Opens the saved API request collections explorer</td></tr>
          <tr><td style="font-weight:bold;">graphql-explorer</td><td>Opens the GraphQL request builder</td></tr>
          <tr><td style="font-weight:bold;">codegen-ui</td><td>Opens the Code Generator UI</td></tr>
          <tr><td style="font-weight:bold;">manage-environment</td><td>Manage workspace environment variables</td></tr>
        </tbody>
      </table>
    </div>
    
    <div class="panel" style="margin-top:12px;">
      <div class="panel-header">Background Tools (Data only)</div>
      <table class="data-table">
        <thead>
          <tr><th>Tool Name</th><th>Description</th></tr>
        </thead>
        <tbody>
          <tr><td style="font-weight:bold;">http-send-request</td><td>Execute an HTTP request and return JSON response data</td></tr>
          <tr><td style="font-weight:bold;">save-request</td><td>Save a request to the active workspace collections</td></tr>
          <tr><td style="font-weight:bold;">get-last-response</td><td>Fetch JSON details of the most recent request execution</td></tr>
          <tr><td style="font-weight:bold;">generate-code-snippet</td><td>Generate code like curl, dart, etc. for a request</td></tr>
          <tr><td style="font-weight:bold;">graphql-execute-query</td><td>Execute a raw GraphQL query</td></tr>
        </tbody>
      </table>
    </div>

    <div style="margin-top:16px; padding:12px; text-align:center; color:var(--muted); font-size:11px;">
      <p>This is the native Dart Model Context Protocol server for APIDash.</p>
    </div>
  </div>

  <script>
    const pending = new Map();
    let nextId = 1;

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
