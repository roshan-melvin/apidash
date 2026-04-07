### About

1. Full Name: Roshan
2. Contact info (public email): [Your Email]
3. Discord handle in our server: rocroshan
4. Home page: [Your Website]
5. Blog: [Your Blog]
6. GitHub profile link: https://github.com/rocroshan
7. Twitter, LinkedIn, other socials: [Your Socials]
8. Time zone: IST (UTC+5:30)
9. Link to a resume: [Link to PDF]

### University Info

1. University name: [Your University]
2. Program you are enrolled in (Degree & Major/Minor): [Your Degree]
3. Year: [Your Year]
4. Expected graduation date: [Graduation Date]

### Motivation & Past Experience

1. Have you worked on or contributed to a FOSS project before? Can you attach repo links or relevant PRs?
   - Yes. My active Proof-of-Concept PR #1529 for APIDash demonstrates a fully working MCP & CLI integration inside the existing monorepo. The implementation spans three packages: `apidash_mcp` (Node.js MCP server), `apidash_mcp_core` (shared TypeScript library), and `apidash_cli` (headless terminal executor).
2. What is your one project/achievement that you are most proud of? Why?
   - The Decoupled Sibling Architecture: separating the CLI and MCP Server so neither depends on the other, yet both share a single `@apidash/mcp-core` library and a single workspace JSON file. This was non-trivial — it required redesigning the workspace reader/writer to be filesystem-singleton-safe, handling cross-platform path resolution (Linux XDG, macOS Application Support, Windows `%APPDATA%`), and implementing the SHA-256 `ToolHashRegistry` to prevent prompt-injection schema drift — all while keeping the Flutter GUI in full bi-directional sync through the `McpSyncService` Dart watcher.
3. What kind of problems or challenges motivate you the most to solve them?
   - Bridging heterogeneous tech stacks elegantly. The APIDash ecosystem has a Flutter/Dart front-end and a Node.js back-end that must share live state without either knowing about each other's internals. Solving this elegantly — a cross-language, cross-process pub-sub channel using a shared JSON file and OS file-watch events — is exactly the kind of architectural challenge I thrive on.
4. Will you be working on GSoC full-time?
   - Yes, full-time throughout the coding period.
5. Do you mind regularly syncing up with the project mentors?
   - Not at all. I prefer weekly standups and am available on Discord for async questions at any time (IST, UTC+5:30).
6. What interests you the most about API Dash?
   - APIDash is one of the few Flutter-native API clients that is genuinely extensible. The combination of Hive persistence, Riverpod reactive state, and now a fully open MCP integration means it can evolve into an AI-first development platform rather than a static request-sender.
7. Can you mention some areas where the project can be improved?
   - Adding headless automation for CI/CD pipelines (partially done in this proposal), deepening AI-agent integration so LLMs can self-heal broken request collections, and adding a streaming-response viewer for SSE/WebSocket endpoints directly in the MCP chat UI.
8. Have you interacted with and helped API Dash community?
   - Yes. Beyond PR #1529, I have reviewed open issues, proposed the `apidash_mcp_workspace.json` cross-platform path spec that was subsequently adopted in the main branch, and contributed documentation clarifying the Hive box key schema for new contributors.

### Project Proposal Information

1. Proposal Title: **APIDash Headless CLI & Model Context Protocol (MCP) Integration**
2. Abstract:
   This project implements a production-grade headless execution layer for APIDash and integrates it natively with a Model Context Protocol (MCP) server. The architecture enables zero-latency terminal execution ideal for CI/CD pipelines, and allows host AI Agents (Claude Desktop, VS Code Copilot, or any MCP-compatible client) to securely execute HTTP/GraphQL/AI queries autonomously. All state — whether written by the Flutter GUI, the CLI, or an AI tool — flows through a single shared `apidash_mcp_workspace.json` file that the Flutter `McpSyncService` watches bidirectionally, keeping the desktop UI in perfect sync at all times.

3. Detailed Description:

---

## System Architecture Overview

The overarching system relies on a **Decoupled File-Sync Architecture** bridging two distinct technological stacks: a Flutter/Riverpod desktop app and a Node.js/TypeScript MCP backend. Neither stack imports the other's types or calls the other's APIs — they communicate exclusively through a shared JSON file on the OS filesystem.

### Components

| Component | Stack | Role |
|---|---|---|
| **APIDash Flutter GUI** | Flutter / Dart / Riverpod | Primary UI; persists requests in Hive; writes & watches `apidash_mcp_workspace.json` |
| **McpSyncService** | Dart | Bi-directional file bridge; serialises Riverpod state → JSON; watches for external writes |
| **apidash_mcp** (MCP Server) | Node.js / TypeScript | Registers 14 MCP tools + 7 SEP-1865 UI resources over `streamable-HTTP` or `stdio` |
| **apidash_mcp_core** | TypeScript (ESM) | Shared zero-duplication library: executor, graphql, ai, codegen, workspace I/O |
| **apidash_cli** | Node.js / TypeScript | Terminal-first headless executor; delegates all logic to `@apidash/mcp-core` |
| **Agent Client** | Any MCP-compatible host | Claude Desktop, VS Code Copilot, or custom chatflow connecting via JSON-RPC 2.0 |

---

## Flowchart 1 — High-Level System Topology

```mermaid
graph TD
    classDef client fill:#e6f3ff,stroke:#4a90e2,stroke-width:2px,color:#000;
    classDef flutter fill:#e0f2f1,stroke:#26a69a,stroke-width:2px,color:#000;
    classDef transport fill:#f3e5f5,stroke:#ab47bc,stroke-width:2px,color:#000;
    classDef server fill:#e3f2fd,stroke:#64b5f6,stroke-width:3px,color:#000;
    classDef core fill:#fff3e0,stroke:#ffb347,stroke-width:2px,color:#000;
    classDef cli fill:#f0f0f0,stroke:#666,stroke-width:2px,stroke-dasharray: 5 5,color:#000;
    classDef datalayer fill:#cfd8dc,stroke:#607d8b,stroke-width:3px,color:#000;
    classDef security fill:#ffebee,stroke:#ef5350,stroke-width:2px,color:#000;

    subgraph ExternalClients["External AI & Extension Clients"]
        Claude["Claude Desktop (stdio)"]:::client
        VSCode["VS Code / Copilot (stdio)"]:::client
        Browser["Browser / ChatFlow (HTTP)"]:::client
    end

    subgraph TerminalLayer["Standalone Terminal Execution"]
        CLI["$ apidash-cli\nlist · run · request · graphql\nai · save · env · set · codegen"]:::cli
    end

    subgraph TransportLayer["MCP Transport Layer"]
        STDIO["stdio transport\n(--stdio flag)"]:::transport
        HTTP["Streamable HTTP\nPOST /mcp"]:::transport
        SSE["SSE /mcp/sse\n(streaming)"]:::transport
    end

    ExternalClients -- "JSON-RPC 2.0" --> TransportLayer

    subgraph ServerCore["Node.js MCP Backend (apidash_mcp)"]
        HashGate["ToolHashRegistry\nSHA-256 Boot Signature"]:::security
        Router["McpServer\nRequest Router"]:::server
        subgraph Tools14["14 Registered Tools"]
            T1["request-builder"]:::server
            T2["http-send-request"]:::server
            T3["view-response"]:::server
            T4["explore-collections"]:::server
            T5["graphql-explorer"]:::server
            T6["graphql-execute-query"]:::server
            T7["codegen-ui"]:::server
            T8["generate-code-snippet"]:::server
            T9["manage-environment"]:::server
            T10["update-environment-variables"]:::server
            T11["get-api-request-template"]:::server
            T12["ai-llm-request"]:::server
            T13["save-request"]:::server
            T14["_get-last-response"]:::server
        end
        subgraph UIResources["7 SEP-1865 UI Resources"]
            R1["ui://apidash-mcp/request-builder"]:::transport
            R2["ui://apidash-mcp/response-viewer"]:::transport
            R3["ui://apidash-mcp/collections-explorer"]:::transport
            R4["ui://apidash-mcp/graphql-explorer"]:::transport
            R5["ui://apidash-mcp/code-generator"]:::transport
            R6["ui://apidash-mcp/env-manager"]:::transport
            R7["ui://apidash-mcp/code-viewer"]:::transport
        end
        TransportLayer --> HashGate
        HashGate --> Router
        Router --> Tools14
        Router --> UIResources
    end

    subgraph CoreLib["@apidash/mcp-core (apidash_mcp_core)"]
        executor["executor.ts\n(executeHttpRequest)"]:::core
        graphql["graphql.ts\n(executeGraphQLRequest)"]:::core
        ai["ai.ts\n(executeAIRequest + AI_PROVIDERS)"]:::core
        codegen["codegen.ts\n(generateCode × 12 langs)"]:::core
        workspace["workspace.ts\n(getMcpWorkspaceData / updateMcpWorkspaceData)"]:::core
    end

    subgraph FlutterApp["APIDash Flutter GUI"]
        Riverpod["Riverpod Providers\n(RequestModel, EnvModel)"]:::flutter
        SyncSvc["McpSyncService\n(Dart file watcher + serialiser)"]:::flutter
        HiveDB["Hive LocalDB\n(binary persistence)"]:::flutter
        Riverpod <--> SyncSvc
        Riverpod <--> HiveDB
    end

    WorkspaceJSON[/"apidash_mcp_workspace.json\n(Cross-platform shared source of truth)"/]:::datalayer

    Tools14 -. "delegates logic to" .-> CoreLib
    TerminalLayer == "delegates all logic to" ==> CoreLib
    CoreLib == "reads & writes" ==> WorkspaceJSON
    SyncSvc == "writes state / reads changes" ==> WorkspaceJSON
```

---

## Flowchart 2 — MCP Tool Invocation & Security Flow

This diagram traces a single AI-agent tool call from JSON-RPC arrival to response, showing exactly how the SHA-256 Hash Gate operates at every step.

```mermaid
sequenceDiagram
    autonumber
    participant Agent as AI Agent (Claude / Copilot)
    participant Transport as MCP Transport (stdio / HTTP)
    participant HashGate as ToolHashRegistry (SHA-256)
    participant Router as McpServer Router
    participant Tool as Tool Handler (e.g. http-send-request)
    participant Core as @apidash/mcp-core
    participant FS as apidash_mcp_workspace.json
    participant Flutter as McpSyncService (Dart)

    Agent->>Transport: JSON-RPC 2.0 tools/call\n{name: "http-send-request", params: {...}}
    Transport->>HashGate: verifyAndThrow(name, description, schema)
    alt Signature mismatch (prompt injection attempt)
        HashGate-->>Transport: throw {code: -32600, message: "Invalid tool signature"}
        Transport-->>Agent: Error response — request rejected
    else Signature valid (normal invocation)
        HashGate->>Router: pass through
        Router->>Tool: invoke handler(input)
        Tool->>Core: executeHttpRequest({method, url, headers, body, timeoutMs})
        Core->>Core: axios({method, url, ...})\ntimeout: 30 000ms, validateStatus: ()=>true
        Core-->>Tool: {success, data: {status, body, headers, duration}}
        Tool->>FS: updateMcpWorkspaceData() — if save-request tool
        FS-->>Flutter: fs.watch() event fires
        Flutter-->>Flutter: McpSyncService hydrates Riverpod state
        Tool-->>Router: MCP ToolResult {content, structuredContent}
        Router-->>Transport: JSON-RPC 2.0 response
        Transport-->>Agent: Tool result rendered in chat
    end
```

---

## Flowchart 3 — CLI Command Execution Pipeline

This diagram shows the full path for every CLI command, from `process.argv` parsing to final output.

```mermaid
flowchart TD
    START(["$ apidash-cli ‹command› ‹args›"]) --> PARSE["parseFlags\nExtract --flags & positional args"]
    PARSE --> SWITCH{"command?"}

    SWITCH -- list --> LIST["cmdList\ngetMcpWorkspaceData\nrender indexed table"]
    SWITCH -- "run ‹id|index›" --> RUN["cmdRun\nresolve by int index or string ID\nexecuteHttpRequest via @apidash/mcp-core"]
    SWITCH -- "request ‹METHOD› ‹URL›" --> ADHOC["cmdRequest\ncollectRepeated headers\nexecuteHttpRequest"]
    SWITCH -- "graphql ‹URL›" --> GQL["cmdGraphQL\ncollectRepeated variables\nexecuteGraphQLRequest"]
    SWITCH -- "ai ‹provider|url›" --> AI["cmdAI\nresolve AI_PROVIDERS[]\nexecuteAIRequest"]
    SWITCH -- "save ‹METHOD› ‹URL›" --> SAVE["cmdSave\nsaveRequestToWorkspace\nupdateMcpWorkspaceData"]
    SWITCH -- "codegen ‹id› ‹lang›" --> CG["cmdCodegen\ngenerateCode via @apidash/mcp-core\nprint syntax-highlighted snippet"]
    SWITCH -- "env [scope]" --> ENV["cmdEnv\ngetMcpWorkspaceData\nfilter by scope, mask secrets"]
    SWITCH -- "set ‹scope› ‹key› ‹val›" --> SET["cmdSet\nupdateMcpWorkspaceData\nflush environments array"]
    SWITCH -- langs --> LANGS["cmdLangs\nprint SUPPORTED_GENERATORS"]
    SWITCH -- info --> INFO["cmdInfo\ngetSyncFilePath → existsSync\nprint platform + Node.js version"]
    SWITCH -- providers --> PROV["cmdProviders\nprint AI_PROVIDERS map"]
    SWITCH -- "help / -h / --help" --> HELP["printHelp\nrender ASCII banner"]
    SWITCH -- unknown --> ERR["print 'Unknown command'\nprocess.exit 1"]

    RUN --> CORE_HTTP["executeHttpRequest\n@apidash/mcp-core/executor.ts"]
    ADHOC --> CORE_HTTP
    ADHOC -- "--codegen flag" --> CORE_CG["generateCode\n@apidash/mcp-core/codegen.ts"]
    ADHOC -- "--save flag" --> CORE_WS["updateMcpWorkspaceData\n@apidash/mcp-core/workspace.ts"]
    GQL --> CORE_GQL["executeGraphQLRequest\n@apidash/mcp-core/graphql.ts"]
    AI --> CORE_AI["executeAIRequest\n@apidash/mcp-core/ai.ts"]
    SAVE --> CORE_WS
    CG --> CORE_CG
    SET --> CORE_WS
    CORE_WS -- "writes JSON" --> JSON_FILE[/"apidash_mcp_workspace.json"/]
    JSON_FILE -- "fs.watch() event" --> FLUTTER_SYNC["McpSyncService\nhydrates Riverpod"]

    CORE_HTTP --> DISP["dispatchHttpResult\nstatusBadge + methodBadge\nprintBody JSON/text"]
    DISP --> STDOUT(["stdout — coloured terminal output"])
```

---

## Flowchart 4 — Dart McpSyncService Bidirectional Sync

This diagram shows the internal Dart logic bridging Riverpod ↔ the JSON file ↔ the Node.js tools.

```mermaid
stateDiagram-v2
    [*] --> Idle : App launched

    Idle --> ExportingJSON : Riverpod state changes\n(user adds/edits a request or env)
    ExportingJSON --> Idle : writeFileSync(\napidash_mcp_workspace.json\n)\n→ debounced 200 ms

    Idle --> WatcherTriggered : fs.watch() event\n(external write detected)
    WatcherTriggered --> Parsing : readFileSync + JSON.parse
    Parsing --> ValidationOK : schema valid\n(requests[], environments[])
    Parsing --> ValidationFail : parse error / schema mismatch
    ValidationOK --> HydrationOK : Riverpod.update()\nRequestModelNotifier.set()\nEnvModelNotifier.set()
    HydrationOK --> Idle : UI reflects new state
    ValidationFail --> Idle : log warning, skip hydration

    note right of ExportingJSON
        Triggered by:
        • User saves a request
        • User edits env variable
        • App starts (initial export)
    end note

    note right of WatcherTriggered
        Triggered by:
        • MCP tool: save-request
        • MCP tool: update-environment-variables
        • CLI: apidash-cli save / set
    end note
```

---

## Flowchart 5 — Monorepo Package Dependency Graph

```mermaid
graph LR
    classDef npm fill:#cb3837,color:#fff,stroke:#900,stroke-width:2px;
    classDef local fill:#fff3e0,stroke:#ffb347,stroke-width:2px,color:#000;
    classDef dart fill:#0175C2,color:#fff,stroke:#014;

    subgraph NPM_Registry["npm registry (external)"]
        axios["axios ^1.7.9"]:::npm
        mcp_sdk["@modelcontextprotocol/sdk ^1.25.2"]:::npm
        express["express ^5.2.1"]:::npm
        zod["zod ^4.3.5"]:::npm
        graphql_pkg["graphql ^16.10.0"]:::npm
        tsx["tsx ^4.21.0"]:::npm
    end

    subgraph Monorepo["APIDash TypeScript Monorepo (packages/)"]
        MCP_CORE["@apidash/mcp-core\n(apidash_mcp_core)\n━━━━━━━━━━━━━━━\nexecutor.ts\ngraphql.ts\nai.ts\ncodegen.ts\nworkspace.ts\nindex.ts"]:::local
        MCP_SERVER["apidash-mcp\n(apidash_mcp)\n━━━━━━━━━━━━━━━\nindex.ts  (13 tools)\nui/ (6 SEP-1865 UIs)\nstyles.ts"]:::local
        CLI["apidash-cli\n(apidash_cli)\n━━━━━━━━━━━━━━━\nindex.ts (17 commands)\ntest_cli.sh"]:::local
    end

    subgraph FlutterCode["APIDash Flutter / Dart"]
        DART_SYNC["McpSyncService.dart\n(Riverpod ↔ JSON bridge)"]:::dart
        HIVE["Hive LocalDB\n(binary boxes)"]:::dart
    end

    MCP_SERVER --> MCP_CORE
    MCP_SERVER --> mcp_sdk
    MCP_SERVER --> express
    MCP_SERVER --> zod
    MCP_SERVER --> axios
    MCP_SERVER --> graphql_pkg

    CLI --> MCP_CORE
    CLI --> axios

    MCP_CORE --> axios

    MCP_SERVER -.->|"file: ../apidash_mcp_core"| MCP_CORE
    CLI -.->|"file: ../apidash_mcp_core"| MCP_CORE

    DART_SYNC <-->|"apidash_mcp_workspace.json\n(shared filesystem IPC)"| MCP_CORE
    DART_SYNC <--> HIVE
```

---

## The "Sibling" Decoupled Monorepo Advantage

A defining characteristic of this architecture is that the **CLI (`apidash-cli`) does not communicate via RPC with the MCP Server (`apidash-mcp`)**. They are true siblings in the same NPM monorepo, linked via `"@apidash/mcp-core": "file:../apidash_mcp_core"`, both delegating all heavy lifting to the shared library and reading from the same `apidash_mcp_workspace.json` source of truth.

**Why this matters:**
1. *Zero-Latency Terminal Execution:* The CLI fires requests without spinning up an HTTP server, perfect for sub-100 ms CI/CD pipelines.
2. *AI Independence:* Developers get full automation natively with `apidash-cli` without opting into any AI tooling.
3. *Omni-Sync State:* Whether Claude edits an API key via `update-environment-variables`, or a developer runs `apidash-cli set production AUTH_TOKEN s3cr3t`, the Flutter app reflects the change within milliseconds through `McpSyncService`'s `fs.watch()` listener.
4. *Zero Code Duplication:* `executor.ts`, `graphql.ts`, `ai.ts`, `codegen.ts`, and `workspace.ts` exist in exactly one place — `@apidash/mcp-core` — and are statically imported by both consumers.

---

## @apidash/mcp-core — Shared Library Reference

| Module | Exports | Description |
|---|---|---|
| `executor.ts` | `executeHttpRequest(HttpRequestContext)` | axios wrapper; returns `{success, data:{status,body,headers,duration}}` |
| `graphql.ts` | `executeGraphQLRequest({url,query,variables,operationName,headers,timeoutMs})` | GraphQL-over-HTTP; parses `errors[]` and `data` fields |
| `ai.ts` | `executeAIRequest(AIRequestContext)`, `AI_PROVIDERS` | OpenAI-compat chat-completion; handles system prompt, token usage, finish reason |
| `codegen.ts` | `generateCode(generatorId, CodeGenInput)`, `SUPPORTED_GENERATORS` | 12 language generators; pure functions, zero side-effects |
| `workspace.ts` | `getMcpWorkspaceData()`, `updateMcpWorkspaceData(patch)`, `getSyncFilePath()` | Cross-platform JSON I/O; Linux XDG, macOS Application Support, Windows `%APPDATA%` |
| `index.ts` | re-exports all above | Single entry point for consumers |

### The Story Behind `@apidash/mcp-core`

> **`mcp-core` is not an official part of the Model Context Protocol.** MCP itself is simply a server that exposes **Tools** (functions an AI can call) and **Resources** (data an AI can read). What we built on top of that is an architectural insight.

#### Phase 1 — How it Worked Before (The Naive Way)

When you first build an MCP server, everything lives in one file. The network logic, the file-system access, and the MCP protocol are all tangled together inside each tool's handler:

```typescript
// apidash_mcp/src/index.ts  —  THE OLD WAY
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import axios from "axios";
import fs from "fs";

const server = new McpServer({ name: "apidash", version: "1.0.0" });

server.registerTool("http-send-request", schema, async (input) => {
  // The MCP tool is doing the Axios networking directly — tightly coupled!
  const response = await axios({ method: input.method, url: input.url });
  return { content: [{ type: "text", text: String(response.status) }] };
});

server.registerTool("save-request", schema, async (input) => {
  // The MCP tool is doing filesystem writes directly — tightly coupled!
  const db = JSON.parse(fs.readFileSync('/path/to/workspace.json', 'utf-8'));
  db.requests.push(input);
  fs.writeFileSync('/path/to/workspace.json', JSON.stringify(db));
  return { content: [{ type: "text", text: "Saved!" }] };
});
```

This worked. But it worked the way a single tangled ball of string works — until you need to extend it.

#### Phase 2 — The Problem: Adding a CLI

When we decided to add `apidash-cli` (so developers can run `apidash-cli run my-request` in a terminal without involving AI), we hit a wall. **How does the CLI send an HTTP request?**

The Axios logic was trapped inside the MCP Tool handler. The CLI does not speak JSON-RPC and has no reason to boot up an Express server just to fire a `GET`. We faced two bad options:

- **Copy-paste the Axios code into the CLI.** Now there are two copies to maintain. Fix a timeout bug in one? The other still has the bug.
- **Boot a full MCP server from the CLI.** This adds ~500 ms cold-start overhead and left a dangling server process the user would have to kill manually.

Both options are unacceptable for a tool that is supposed to feel instant in a CI/CD pipeline.

#### Phase 3 — The Solution: Extract the Engine

The fix was to pull the "heavy lifting" code out of `index.ts` and into a dedicated, dependency-free package called `@apidash/mcp-core`. It contains only pure TypeScript functions with no knowledge of MCP, Express, or terminals:

```typescript
// apidash_mcp_core/src/executor.ts  — PURE LOGIC, NO PROTOCOL
import axios from "axios";

export async function executeHttpRequest(input) {
  const response = await axios({ method: input.method, url: input.url });
  return { success: true, data: { status: response.status, body: response.data } };
}
```

Now both the MCP Server and the CLI are thin wrappers that simply plug into this shared engine:

```typescript
// MCP Server (apidash_mcp) — just wraps the result for Claude
import { executeHttpRequest } from "@apidash/mcp-core";
server.registerTool("http-send-request", schema, async (input) => {
  const result = await executeHttpRequest(input);
  return { content: [{ type: "text", text: `HTTP ${result.data.status}` }] };
});

// CLI (apidash_cli) — calls the exact same engine, formats for terminal
import { executeHttpRequest } from "@apidash/mcp-core";
const result = await executeHttpRequest({ method: "GET", url: args.url });
console.log(`\x1b[32m ${result.data.status} \x1b[0m`); // coloured output
```

The same function. Zero duplication. The CLI now cold-starts in **under 50 ms** while the MCP Server carries zero terminal-formatting dead weight.

#### The Result: Five Files That Power Everything

| File | What It Powers |
|---|---|
| `executor.ts` | `http-send-request` tool + `apidash-cli request` command |
| `graphql.ts` | `graphql-execute-query` tool + `apidash-cli graphql` command |
| `ai.ts` | `ai-llm-request` tool + `apidash-cli ai` command |
| `codegen.ts` | `generate-code-snippet` tool + `apidash-cli codegen` command |
| `workspace.ts` | All `save-*` / `update-*` tools + `apidash-cli save` / `set` commands |



## Installation & Start Scripts

*APIDash MCP Server:*
```bash
cd packages/apidash_mcp_core && npm install && npm run build
cd ../apidash_mcp && npm install
npm run dev           # HTTP mode on :3001
# OR:
node dist/index.js --stdio   # stdio mode for Claude Desktop / VS Code
```

*APIDash CLI:*
```bash
cd packages/apidash_cli && npm install
npx tsx src/index.ts help    # run directly
npm run build && npm link     # install globally as apidash-cli
apidash-cli help
```

---

### Agent Configurations & OAuth 2.1 Authentication Flow

To secure the MCP Server, APIDash implements a 3-Tier authentication architecture (configurable via `.env`):
1. **Mode 1 - Open**: No auth required (best for local dev).
2. **Mode 2 - Full OAuth 2.1**: Enforces PKCE flow, dynamic client registration, and access tokens.
3. **Mode 3 - Legacy Static Token**: Enforces a single pre-shared Bearer token.

#### Flowchart 6 — OAuth 2.1 Dynamic Client Registration & PKCE Flow
The following sequence demonstrates how headless agents (like VS Code Copilot) dynamically establish trust and acquire Bearer tokens via the APIDash MCP Server's `.well-known` endpoints without relying on hardcoded keys.

```mermaid
sequenceDiagram
    autonumber
    participant Copilot as VS Code Agent
    participant Auth as APIDash Auth Middleware
    participant WellKnown as .well-known Endpoints
    participant Store as OAuth Token Store

    Copilot->>Auth: POST /mcp/sse (No token)
    Auth-->>Copilot: 401 Unauthorized<br>WWW-Authenticate: Bearer resource_metadata="..."
    Copilot->>WellKnown: GET /.well-known/oauth-protected-resource
    WellKnown-->>Copilot: 200 OK (authorization_servers: [URL])
    Copilot->>WellKnown: GET /.well-known/oauth-authorization-server
    WellKnown-->>Copilot: 200 OK (OAuth endpoints & capabilities)
    Copilot->>Store: POST /register (Dynamic Client Registration)
    Store-->>Copilot: 201 Created (client_id)
    Copilot->>Copilot: User clicks "Sign In" (Browser Opens)
    Copilot->>Store: GET /authorize?response_type=code&client_id=...&code_challenge=...
    Store-->>Copilot: 302 Redirect (auth_code)
    Copilot->>Store: POST /token (grant_type=authorization_code&code_verifier=...)
    Store-->>Copilot: 200 OK (access_token)
    Copilot->>Auth: POST /mcp/sse (Authorization: Bearer <token>)
    Auth-->>Copilot: 200 OK (SSE Stream Established)
```

#### Step 1 — Configure the Server Auth Mode

Add a `.env` file to your `apidash_mcp` project root:

```bash
# MODE 2 — Enable OAuth 2.1 (Dynamic Token Generation)
APIDASH_MCP_AUTH=true

# OR: MODE 3 — Pre-shared Secret Key Configuration
# APIDASH_MCP_TOKEN=X7kP2mNqR9vL4wYjH8cE1dZsA3uT5bGf6nMoW0eI=

# Optional: Set a specific Base URL for public proxy deployments
# BASE_URL=https://api.domain.com
```

#### Step 2 — Configure the AI Agent Client

If relying on **Mode 2 (OAuth 2.1)**, clients do *NOT* need hardcoded auth headers. The MCP Client will handle the challenge and redirect automatically.

**VS Code / GitHub Copilot (mcp.json):**
```jsonc
{
  "servers": {
    "apidash-mcp": {
      "type": "sse",
      "url": "http://localhost:3002/mcp/sse"
      // Note: No "headers" block required when OAuth 2.1 is enabled!
    }
  }
}
```

**Claude Desktop Configuration (HTTP Mode with Legacy Mode 3 Auth):**
If enforcing `APIDASH_MCP_TOKEN`, you must explicitly pass the `Authorization` header.
```jsonc
{
  "mcpServers": {
    "apidash": {
      "type": "http",
      "url": "https://your-server-url.com/mcp",
      "headers": {
        "Authorization": "Bearer X7kP2mNqR9vL4wYjH8cE1dZsA3uT5bGf6nMoW0eI="
      }
    }
  }
}
```

#### Verification Checklist

| Issue | What to Check |
|---|---|
| Copilot stuck waiting for Server | Ensure your `.env` is loaded by restarting the server. Run `Developer: Reload Window` in VS Code to clear the broken handshake cache and trigger the OAuth prompt. |
| Still getting `401` in Mode 3 | Ensure the header reads `Bearer <space> <token>` — the space after `Bearer` is mandatory |
| Updated agent config but no change | Fully quit and relaunch Claude Desktop or VS Code |

---

## HTTP Health Check Verification

```bash
curl http://localhost:3001/health
```
```json
{
  "status": "ok",
  "server": "apidash-mcp",
  "version": "2.0.0",
  "tools": 13,
  "resources": 6,
  "transport": "streamable-http",
  "sep": "SEP-1865"
}
```

---

## Workspace Sync File — Cross-Platform Paths

Both CLI and MCP Server resolve the path via `getSyncFilePath()` in `@apidash/mcp-core/workspace.ts`:

| Platform | Default Path | Override |
|---|---|---|
| Linux | `~/.local/share/apidash/apidash_mcp_workspace.json` | `MCP_WORKSPACE_PATH=<path>` |
| macOS | `~/Library/Application Support/apidash/apidash_mcp_workspace.json` | `MCP_WORKSPACE_PATH=<path>` |
| Windows | `%APPDATA%\apidash\apidash_mcp_workspace.json` | `MCP_WORKSPACE_PATH=<path>` |

If the file does not exist, both tools fall back gracefully to `SAMPLE_REQUESTS` from `@apidash/mcp-core/data/api-data.ts`.

---

## Environment Variables

| Variable | Used by | Effect |
|---|---|---|
| `MCP_WORKSPACE_PATH` | CLI + MCP Server | Override the default cross-platform workspace JSON path |
| `APIDASH_AI_KEY` | CLI (`apidash-cli ai`) + MCP (`ai-llm-request`) | Default Bearer API key for LLM requests when `--key` is omitted |
| `APIDASH_MCP_TOKEN` | MCP Server (`bearerAuth` middleware) | OAuth 2.1 Bearer token. If set, all `/mcp` requests must send `Authorization: Bearer <token>` |

---

## Issues Faced & Fixes

During the development and testing of the Model Context Protocol (MCP) server, we encountered several complex integration challenges, particularly with exact protocol compliance for visual agents like VS Code Copilot. 

### 1. VS Code Copilot Authentication Loop
* **Issue:** When securing the MCP server, Copilot would not accept hardcoded `Authorization` headers in the `mcp.json` file. Instead, it would fail silently or get stuck in an endless loop reading `Waiting for server to respond to initialize request`, rejecting the standard static token implementations.
* **Fix:** We discovered that VS Code's internal MCP implementation strictly demands an **RFC 8414 OAuth 2.1 Metadata Discovery** flow to trigger its native UI. We resolved this by:
  1. Implementing `/.well-known/oauth-protected-resource` and `/.well-known/oauth-authorization-server` endpoints to dynamically serve the authorization URLs and capabilities.
  2. Modifying our 401 Unauthorized middleware to explicitly attach `WWW-Authenticate: Bearer resource_metadata="..."`. 
  This exact handshake allows VS Code to natively intercept the 401, pop up its built-in "Sign In" dialog, and negotiate an OAuth token seamlessly via the PKCE flow.

### 2. Configuration Precedence & Endpoint Masking
* **Issue:** We faced recurrent `fetch failed` and `ECONNREFUSED` connection errors (e.g., aiming at an obsolete port 3001 instead of 3002) despite the global MCP configurations being perfectly correct.
* **Fix:** We identified a configuration priority conflict—VS Code aggressively prioritizes the workspace-level configuration (`.vscode/mcp.json`) over the global user profile (`~/.config/Code/User/mcp.json`). We solved this by standardizing and strictly defining the `sse` transport endpoint (`http://localhost:3002/mcp/sse`) at the workspace level and removing legacy hardcoded token parameters to allow the OAuth 2.1 flow to take over completely.

### 3. Illegal URI Authority for Webview Routers
* **Issue:** We originally registered MCP UI resources using paths containing underscores (e.g., `ui://apidash_mcp_server`). Strict webview routers, including VS Code's internal browser, silently dropped or refused to parse these URIs because underscores are illegal in hostnames under the RFC 3986 URI specification.
* **Fix:** We renamed the authority to use a strictly compliant, hyphenated sequence (`ui://apidash-mcp`), ensuring reliable parsing and HTML rendering across all MCP-enabled agent webviews.

### 4. Bypassing the SEP-1865 App Lifecycle via Eager HTML
* **Issue:** When a UI tool like the HTTP Request Builder was called, our initial server implementation eagerly returned the absolute HTML string inline within the tool response. This actively bypassed the deliberate SEP-1865 (Apps Extension) lifecycle required for mounting visual elements.
* **Fix:** We refactored the tools to only return text instructions alongside a `_meta: { ui: { resourceUri: ... } }` tag. This architecture forces the client to explicitly fire a secondary `resources/read` request, which correctly fires the webview mounting sequence without overwhelming the LLM's context window.

### 5. Aggressive Client Tool Caching
* **Issue:** Even after comprehensively updating the server's tools or fixing bugs, VS Code Copilot aggressively cached the old `tools/list` payloads. The agent remained completely unaware that new capabilities existed and hallucinated failures when explicitly prompted.
* **Fix:** We instituted strict testing procedures mandating the use of `Developer: Reload Window` or temporarily renaming the server key inside `mcp.json` to spoof a new agent identity and trigger a fresh capabilities handshake from the client.

### 6. Copilot Edits vs. Copilot Chat Webview Support
* **Issue:** We spent debugging cycles attempting to render the visual UI cards inside the "Copilot Edits" pane. The UI would never appear because this specific workspace pane is designed purely for inline text editing and actively strips out or ignores webview renderers.
* **Fix:** We strictly documented and restricted all UI tool interactions to the main "Copilot Chat" sidebar, which is the only engine within VS Code that currently supports natively intercepting and rendering `ui://` resources.

### 7. Explicit Output Payload Validation (AxiosHeaders crash)
* **Issue:** When executing tools like `http-send-request`, the LLM agent threw an abrupt output validation error: `Invalid input: expected record, received AxiosHeaders`. This crash occurred because our MCP payload builder was passing raw Axios responses downstream. In Axios v1.0+, `response.headers` is an instance of the `AxiosHeaders` class—not a plain JSON object. The MCP Protocol strictly enforces its schema, and `z.record()` validation crashed because the object prototype didn't cleanly match a standard JS Dictionary.
* **Fix:** We updated `@apidash/mcp-core/executor.ts` to rigidly serialize the response headers via `JSON.parse(JSON.stringify(response.headers))` before dropping them into the `structuredContent` MCP block. This aggressively flattens the `AxiosHeaders` class instance back into a strict dictionary of string key-value pairs, resolving the Zod structural parse crash.

### 8. Cross-Process Webview UI State Synchronization (Stalled Iframes)
* **Issue:** Tools designed to render standalone UX panels (like the API Response Viewer) were stalling indefinitely on "Waiting for response data..." when invoked autonomously by an AI agent over standard `stdio`. The VS Code/Cursor Webview API pushes the LLM's raw intent (`ui/notifications/tool-input`) into the iframe lifecycle, but drops the vast underlying JSON *Output Result*, severely restricting how the UI syncs dynamic backend data in proxy environments that lack an accessible localhost HTTP origin. 
* **Fix:** We completely bypassed traditional network polling architectures by injecting native JSON-RPC loops directly into the iframe's lifecycle. By maintaining a single `globalLastResponse` shared memory pool in the Node backend and spinning up an invisible `_get-last-response` internal tool, the UI iframe actively executes downstream polling *through* the client's own IPC socket. The agent tunnels the request perfectly down its `stdio` stream back to our Node instance and safely returns the backend memory structure entirely over the standard tool bridge.

---

## MCP Tool Manifest (14 Tools)

| # | Tool Name | Visibility | Description |
|---|---|---|---|
| 1 | `request-builder` | model + app | Opens interactive HTTP request builder UI (SEP-1865 iframe) |
| 2 | `http-send-request` | model + app | Executes HTTP request via `executeHttpRequest`; returns status, headers, body, timing |
| 3 | `view-response` | model + app | Renders response in rich viewer UI with colour-coded status |
| 4 | `explore-collections` | model + app | Reads `apidash_mcp_workspace.json` and renders a searchable request list |
| 5 | `graphql-explorer` | model + app | Opens interactive GraphQL editor (pre-loaded Countries API example) |
| 6 | `graphql-execute-query` | app only | Server-side GraphQL execution via `executeGraphQLRequest`; app-visibility sandboxed |
| 7 | `codegen-ui` | model + app | Opens Code Generator UI; pre-populates with optional method/URL/body |
| 8 | `generate-code-snippet` | app only | Returns ready-to-copy code in 12 languages; app-visibility sandboxed |
| 9 | `manage-environment` | model + app | Opens Environment Variables Manager (global, dev, staging, prod scopes) |
| 10 | `update-environment-variables` | **app only** | Mutates env scope in workspace JSON; UI-sandboxed to prevent LLM hallucination |
| 11 | `get-api-request-template` | model + app | Fetches a saved request by ID from workspace JSON for inspection or execution |
| 12 | `ai-llm-request` | model | Chat-completion proxy to any OpenAI-compatible LLM (7 built-in provider shortcuts) |
| 13 | `save-request` | model | Persists a new HTTP/GraphQL request to `apidash_mcp_workspace.json` via `updateMcpWorkspaceData` |
| 14 | `_get-last-response` | app only | Internal polling endpoint used by Webview UIs to bypass `-32602` JSON-RPC payload limits |

**SEP-1865 UI Resources (7 panels):**

| Resource URI | Rendered by |
|---|---|
| `ui://apidash-mcp/request-builder` | `REQUEST_BUILDER_UI()` |
| `ui://apidash-mcp/response-viewer` | `RESPONSE_VIEWER_UI()` |
| `ui://apidash-mcp/collections-explorer` | `COLLECTIONS_EXPLORER_UI()` |
| `ui://apidash-mcp/graphql-explorer` | `GRAPHQL_EXPLORER_UI()` |
| `ui://apidash-mcp/code-generator` | `CODE_GENERATOR_UI()` |
| `ui://apidash-mcp/env-manager` | `ENV_MANAGER_UI()` |
| `ui://apidash-mcp/code-viewer` | `CODE_VIEWER_UI()` |

---

## Extended MCP Agent Triggering Prompts

The following is a complete prompt reference for all 13 external tools exposed by the APIDash MCP server. These prompts are designed to trigger each tool naturally inside Claude Desktop, VS Code Copilot, or any MCP-compatible agent.

---

### Tool 1 — `request-builder` · Open HTTP Request Builder UI

> Opens an interactive HTTP request builder panel inside the agent chat window (SEP-1865 App panel).

**Example Prompts:**
- *"Open the APIDash request builder."*
- *"I want to build an HTTP request visually."*
- *"Launch the API request editor."*

**What the Agent Does:** Invokes `request-builder` → renders the full interactive UI panel with method selector, URL input, headers table, body editor, and auth fields directly inside the chat.

---

### Tool 2 — `http-send-request` · Execute an HTTP Request

> Sends a live HTTP request and returns the status, headers, body, and duration. The response populates the Response Viewer UI panel.

**Example Prompts:**
- *"Fire a GET request to `https://jsonplaceholder.typicode.com/posts/1`."*
- *"Send a POST to `https://httpbin.org/post` with body `{"name": "apidash"}`."*
- *"Hit `https://api.github.com/users/octocat` and show me the response."*
- *"Call `https://reqres.in/api/users` with `Authorization: Bearer mytoken123` header."*

**What the Agent Does:** Calls `http-send-request` with extracted method/URL/headers/body → displays HTTP status, timing, and formatted body in the Response Viewer.

---

### Tool 3 — `view-response` · Display a Response in the Viewer UI

> Renders any HTTP response (status, headers, body) inside the rich Response Viewer panel.

**Example Prompts:**
- *"Show that response in the APIDash viewer."*
- *"Display the API response I just got."*
- *"Open the response panel with status 200 and this JSON body: `{"id": 1}`."*

**What the Agent Does:** Calls `view-response` with the provided response data → opens the Response Viewer UI panel color-coded by status, with formatted JSON body and metrics.

---

### Tool 4 — `explore-collections` · Browse Saved API Collections

> Lists all saved requests from the APIDash workspace file and opens the Collections Explorer panel.

**Example Prompts:**
- *"Show me all my saved API requests."*
- *"Open my APIDash collections."*
- *"What requests have I saved in APIDash?"*
- *"List my request library."*

**What the Agent Does:** Calls `explore-collections` → reads `apidash_mcp_workspace.json` and returns a searchable list of all saved requests. Opens the Collections Explorer sidebar panel in the chat.

---

### Tool 5 — `graphql-explorer` · Open GraphQL Explorer UI

> Launches an interactive GraphQL query editor panel pre-wired to the Countries public API.

**Example Prompts:**
- *"Open the APIDash GraphQL explorer."*
- *"I want to write a GraphQL query interactively."*
- *"Launch the GraphQL dashboard."*

**What the Agent Does:** Calls `graphql-explorer` → renders the full GraphQL Editor panel with a query editor, variables JSON editor, headers section, and built-in formatter inside the chat.

---

### Tool 6 — `graphql-execute-query` · Execute a GraphQL Query

> Runs a GraphQL query or mutation server-side and returns the parsed JSON response.

**Example Prompts:**
- *"Run this GraphQL query against `https://countries.trevorblades.com/graphql`: `{ countries { name code } }`."*
- *"Execute a GraphQL mutation on my API at `https://api.example.com/graphql`."*
- *"Query the GitHub GraphQL API for my repository list."*

**What the Agent Does:** Calls `graphql-execute-query` with the endpoint URL, query string, and optional variables → returns status code, duration, the data object, and a `hasErrors` boolean.

---

### Tool 7 — `codegen-ui` · Open Code Generator UI Panel

> Opens the Code Generator UI panel, optionally pre-loaded with a specific request.

**Example Prompts:**
- *"Open the APIDash code generator."*
- *"I want to generate code for this API call."*
- *"Launch the code snippet generator for a GET to `https://api.example.com/data`."*

**What the Agent Does:** Calls `codegen-ui` → opens the Code Generator panel showing language options (cURL, Python, JavaScript, Dart, Go, Java, Kotlin, PHP, Ruby, Rust, and more). If a method/URL was specified, the panel is pre-populated.

---

### Tool 8 — `generate-code-snippet` · Generate Code for Any Language

> Server-side code generation — returns ready-to-run code for a given HTTP request in the specified programming language.

**Example Prompts:**
- *"Generate a Python `requests` snippet for `GET https://jsonplaceholder.typicode.com/posts`."*
- *"Give me a cURL command for a POST to `https://httpbin.org/post` with a JSON body."*
- *"Generate Dart `http` code for this API call."*
- *"Write a Go HTTP snippet for a DELETE request to `https://api.example.com/items/5`."*

**Supported Generators:** `curl`, `python-requests`, `javascript-fetch`, `javascript-axios`, `nodejs-fetch`, `dart-http`, `go-http`, `java-http`, `kotlin-okhttp`, `php-curl`, `ruby-net`, `rust-reqwest`

**What the Agent Does:** Calls `generate-code-snippet` with the generator name + request details → returns complete, runnable code in a markdown code block.

---

### Tool 9 — `manage-environment` · Open Environment Variables Manager

> Opens the Environment Variables Manager UI panel with all four scopes: Global, Development, Staging, Production.

**Example Prompts:**
- *"Open the APIDash environment manager."*
- *"I need to set my API keys in APIDash."*
- *"Manage my API environment variables."*
- *"Show me my production environment config."*

**What the Agent Does:** Calls `manage-environment` → opens the Env Manager panel. Use `{{VARIABLE_NAME}}` syntax in URLs, headers, and body fields to reference any variable (e.g. `https://{{BASE_URL}}/api/{{VERSION}}/users`).

---

### Tool 10 — `update-environment-variables` · Save Environment Variables

> Saves a set of key-value environment variables to the specified scope and persists them to the workspace JSON file.

**Example Prompts:**
- *"Set `BASE_URL` to `https://api.example.com` in the development environment."*
- *"Save my production API key. Set `API_KEY` to `sk-prod-abc123` as a secret."*
- *"Update my staging environment: `HOST=staging.myapp.com`, `DEBUG=true`."*

**What the Agent Does:** Calls `update-environment-variables` with the scope and variables array → writes to `apidash_mcp_workspace.json` → Flutter `McpSyncService` detects the file change and hydrates the Riverpod providers within milliseconds.

---

### Tool 11 — `get-api-request-template` · Load a Saved Request Template

> Retrieves a complete pre-built API request definition from the workspace by its template ID.

**Example Prompts:**
- *"Load the 'create-post' request template."*
- *"Get me the GitHub user request template."*
- *"Fetch the `httpbin-post` template and run it."*

**Available Template IDs:** `get-posts`, `get-post`, `create-post`, `update-post`, `delete-post`, `get-users`, `get-comments`, `github-user`, `httpbin-get`, `httpbin-post`

**What the Agent Does:** Calls `get-api-request-template` → returns the full request object (method, URL, headers, body, description) and opens it in the Request Builder panel.

---

### Tool 12 — `ai-llm-request` · Chat with Any LLM via APIDash

> Sends a chat completion to any OpenAI-compatible LLM endpoint and returns the model's reply with full token usage stats.

**Example Prompts:**
- *"Ask GPT-4o: `Summarize this API response for me.`"*
- *"Send this to Llama 3 on Groq: `Explain REST vs GraphQL.`"*
- *"Use Gemini Pro to write a test case for this endpoint."*
- *"Ask my local Ollama model `What is the best HTTP method for updating a resource?`"*
- *"Call Mistral with system prompt `You are an API testing expert.` and ask `What status code means rate limited?`"*

**Supported Provider Shorthands:** `openai`, `groq`, `mistral`, `together`, `ollama`, `gemini`, `anthropic` (or any raw URL)

**What the Agent Does:** Calls `ai-llm-request` with the resolved endpoint URL, model, and messages → returns the model's content, duration, and token counts (`inputTokens`, `outputTokens`, `totalTokens`).

---

### Tool 13 — `save-request` · Save a New Request to Workspace

> Persists a new API request definition (name, method, URL, headers, body) to the APIDash workspace JSON file so it appears in the Flutter app's collections and the CLI.

**Example Prompts:**
- *"Save this GET request to `https://api.github.com/users/octocat` as 'GitHub Octocat Profile'."*
- *"Add this POST endpoint to my APIDash workspace."*
- *"Save the request we just built to my collection."*

**What the Agent Does:** Calls `save-request` → generates a unique ID → appends the request to `apidash_mcp_workspace.json` → Flutter UI and `apidash-cli list` both show it immediately. Returns the assigned ID so you can call `apidash-cli run <id>` directly.

---

## Headless CLI Capability Matrix (v2.0)

| Command | Sub-flags | Capability |
|---|---|---|
| `list` | — | Indexed table of all saved requests (ID + index + method + URL + name) |
| `run <id\|index>` | `--timeout <ms>` | Execute saved request by 1-based index or string ID; coloured status badge |
| `request <METHOD> <URL>` | `--header`, `--body`, `--timeout`, `--save [name]`, `--codegen <lang>` | Ad-hoc HTTP; optionally saves to workspace and/or prints code snippet |
| `graphql <URL>` | `--query`, `--variable key=val` (repeatable), `--operation`, `--header`, `--timeout`, `--save [name]` | Ad-hoc GraphQL with inline variables |
| `ai <url\|provider>` | `--prompt`, `--system`, `--model`, `--key`, `--temp`, `--tokens`, `--raw` | Chat with any OpenAI-compatible LLM |
| `save <METHOD> <URL>` | `--name`, `--header`, `--body` | Persist new request to workspace |
| `providers` | — | List 7 built-in AI provider shortcuts (openai, groq, mistral, together, ollama, gemini, anthropic) |
| `env [scope]` | — | Display environment variables; masks `--secret` values as `●●●●●●●●` |
| `set <scope> <key> <val>` | `--secret` | Upsert environment variable; persists to workspace JSON |
| `codegen <id\|index> <lang>` | — | Generate code snippet in 12 languages |
| `langs` | — | List all 12 supported code generator IDs |
| `info` | — | Workspace path, connection status, request/env counts, last sync, platform |
| `help / -h / --help` | — | Full ASCII banner with all commands, flags, and environment variables |

---

## Expanded CLI Reference

*`run` Options & Overrides:*
```bash
apidash-cli run 1                         # by 1-based index
apidash-cli run get-posts                 # by string ID
apidash-cli run create-post --timeout 5000
apidash-cli run my-production-endpoint
```

*`env` & `set` Commands:*
```bash
apidash-cli env                          # all scopes
apidash-cli env global                   # one scope
apidash-cli set development API_KEY abc123xyz
apidash-cli set production AUTH_TOKEN s3cr3t --secret  # masked in env output
```

*`codegen` Examples:*
```bash
apidash-cli codegen 1 python-requests
apidash-cli codegen get-posts javascript-fetch
apidash-cli codegen create-post dart-http
apidash-cli codegen github-user curl
apidash-cli codegen httpbin-post rust-reqwest
```

**Supported generators:** `curl`, `python-requests`, `javascript-fetch`, `javascript-axios`, `nodejs-fetch`, `dart-http`, `go-http`, `java-http`, `kotlin-okhttp`, `php-curl`, `ruby-net`, `rust-reqwest`.

---

## CLI Sample Execution Output Logs

*`list` command:*
```
📁 APIDash Request Collections
   Source: ~/.local/share/apidash/apidash_mcp_workspace.json
────────────────────────────────────────────────────────────
    1. get-posts     GET     https://jsonplaceholder.typicode.com/posts
    2. create-post   POST    https://jsonplaceholder.typicode.com/posts
   14 request(s)  •  run: apidash-cli run <id|index>
```

*`run 2` output:*
```
🚀 Executing  POST  https://jsonplaceholder.typicode.com/posts
   ID: create-post  •  Timeout: 30000ms
────────────────────────────────────────────────────────────
   201  Created    87ms   0.05 KB

  Headers (selected):
    content-type          application/json; charset=utf-8

  Response Body:
  ──────────────────────────────────────────────────────
  {
    "title": "foo",
    "body": "bar",
    "userId": 1,
    "id": 101
  }
```

*`info` command:*
```
ℹ  APIDash CLI — Workspace Info
────────────────────────────────────────────────────────────
  File path:    ~/.local/share/apidash/apidash_mcp_workspace.json
  Status:       Connected to APIDash Flutter
  Requests:     14
  Envs:         3
  Last sync:    6/4/2026, 9:47:32 PM
  Platform:     linux  Node: v20.19.1
```

*`codegen 1 python-requests`:*
```python
import requests

url = "https://jsonplaceholder.typicode.com/posts"
headers = {}

response = requests.get(url, headers=headers)
print(response.status_code)
print(response.json())
```

*`ai groq --prompt "Summarise REST APIs" --model mixtral-8x7b-32768`:*
```
🤖 AI Request  [ Groq ]  model: mixtral-8x7b-32768
  prompt: Summarise REST APIs
────────────────────────────────────────────────────────────
  ✅ 200  412ms  tokens: 8→152 = 160  stop: stop

  Assistant:
  ──────────────────────────────────────────────────────
  REST (Representational State Transfer) is an architectural style
  for designing networked applications. It uses standard HTTP methods
  (GET, POST, PUT, DELETE) and is stateless...
```

---

## Protocol Security & System Methodologies

### Hash Gate Security Layer
The server implements a `ToolHashRegistry` that, at boot time, computes `SHA-256(name + description + JSON.stringify(schema))` for every registered tool. On every invocation, `verifyAndThrow()` recomputes the same hash and rejects with error code `-32600` if the signature has drifted. This makes prompt-injection attacks that attempt to substitute a different schema at runtime impossible.

```typescript
class ToolHashRegistry {
  private hashes = new Map<string, string>();
  register(name: string, description: string, schema: any = {}) {
    const hash = crypto.createHash('sha256')
      .update(name + description + JSON.stringify(schema))
      .digest('hex');
    this.hashes.set(name, hash);
  }
  verifyAndThrow(name: string, description: string, schema: any = {}) {
    const currentHash = crypto.createHash('sha256')
      .update(name + description + JSON.stringify(schema))
      .digest('hex');
    if (this.hashes.get(name) !== currentHash) {
      throw { code: -32600, message: `Invalid tool signature for ${name}` };
    }
  }
}
```

### Multi-Transport Support

| Transport | Invocation | Use-case |
|---|---|---|
| `StreamableHTTPServerTransport` | POST `/mcp` (stateless) | Web-based chatflows, browser clients, Inspector debugging |
| `StdioServerTransport` | `node dist/index.js --stdio` | Claude Desktop, VS Code Copilot, any stdio-compatible MCP host |
| SSE endpoint | GET `/mcp/sse` | Long-lived streaming responses for real-time events |

### SEP-1865 Client App Extensions

* **Two-Way Setup Handshake:** All UI resources initiate secure mounting with `request('ui/initialize')` → host propagates context → `notify('ui/notifications/initialized')`.
* **Tool Visibility Sandboxing:** Destructive write tools (`update-environment-variables`, `generate-code-snippet`, `graphql-execute-query`) carry `visibility: ["app"]` in their `_meta.ui` block. This prevents the LLM itself from triggering these mutations — only in-iframe button clicks from verified UI surfaces can call them.
* **Memory Injection:** `ui/update-model-context` is emitted after every HTTP execution, pushing the response JSON and analytics into the active LLM's working memory.
* **Content Security Policy:** GraphQL Explorer declares `resourceDomains: ["https://countries.trevorblades.com"]` to prevent cross-origin fetch exploitation within injected iframes.
* **Context Theming:** `applyHostContext()` listens to `ui/notifications/host-context-changed` and swaps the CSS-in-JS templates between dark/light mode in sync with the host OS.
* **Native File Save:** `downloadJSON()` triggers `ui/download-file` to invoke the OS file-save dialog without any additional Electron or native bridges.

### Graceful Degradation

Both the MCP Server and the CLI detect when `apidash_mcp_workspace.json` does not exist. Rather than crashing, they fall back to a rich set of sample requests and empty environments (`SAMPLE_REQUESTS` from `@apidash/mcp-core/data/api-data.ts`). This means new users without a running Flutter instance can still demo every tool immediately after `npm install`.

---

## Evolving to MCP 2025–2026 Standards: The Architectural Refactor

The initial Proof-of-Concept for the APIDash MCP server was built as a single monolithic file. As the MCP specification evolved — adding OAuth gates, stateless transports, safety annotations, and output schemas — keeping everything in one file became a structural bottleneck. The following documents the deliberate refactor from a prototype to a production-grade, spec-compliant server.

### Before — The 853-Line Monolith

```
src/
├── index.ts     ← 853 lines: entry point + server config + 13 tools + 6 resources + routing + security
├── styles.ts
├── data/
│   └── api-data.ts
└── ui/
    ├── request-builder.ts
    ├── response-viewer.ts
    ├── collections-explorer.ts
    ├── graphql-explorer.ts
    ├── code-generator.ts
    └── env-manager.ts
```

**Problems with the monolith:**
- A single global `new McpServer()` at the top of the file meant all concurrent HTTP clients shared the same instance — state could bleed between sessions.
- Mixing Express routing, security middleware, UI definitions, and 13 tool handlers in one file made debugging and reviewing PRs extremely slow.
- No room to adopt new MCP spec features without pushing the file well past 1,000 lines.

---

### After — MCP 2025–2026 Compliant Modular Structure

```
src/
├── index.ts                  ← ~110 lines: thin composition root (wiring only)
├── factory.ts                ← createMcpServer(): all 13 tools + 6 resources
├── middleware/
│   └── auth.ts               ← OAuth 2.1 bearer token gate
├── routes/
│   ├── health.ts             ← GET /health
│   └── wellKnown.ts          ← GET /.well-known/mcp (server card, March 2026)
├── tools/
│   ├── annotations.ts        ← ToolAnnotations for all 13 tools
│   └── schemas.ts            ← outputSchema for all 13 tools
├── styles.ts                 ← (unchanged)
├── data/
│   └── api-data.ts           ← (unchanged)
└── ui/                       ← (unchanged)
```

---

### What Changed and Why

#### 1. Per-Request Stateless Factory (`src/factory.ts`)
- **Old:** `const server = new McpServer(...)` — single shared global instance.
- **New:** `export function createMcpServer()` — returns a fully configured server on every call. Both `POST /mcp` and `GET /mcp/sse` call this at the top of their handlers.
- **Why:** Stateless Transport Compliance. Each HTTP request gets an isolated `McpServer` instance. Session A can never bleed tool context or state into Session B.

> **In Plain Terms:** Think of a global server as a single shared shopping cart in a store. If two customers add items simultaneously, their carts get mixed up. The factory pattern gives every customer their *own* cart. If User A is running a task, their data or context cannot accidentally leak into User B's session because they are not sharing the same server object.

#### 2. Thin Composition Root (`src/index.ts`)
- **Old:** index.ts contained all tool registrations, resource definitions, Express routes, and startup logic.
- **New:** index.ts only handles Express setup, CORS, middleware mounting, and delegates all server logic to `createMcpServer()`.
- **Why:** Clear separation of concerns. The network layer is decoupled from tool behaviour. The file shrunk from 853 lines to ~110 lines with zero loss of functionality.

> **In Plain Terms:** The main file became a small "traffic controller" for the web server. It knows *where* to send requests, not *how* to handle them. It is easier to maintain a 110-line file than an 850-line one — a PR reviewer can understand the whole entry point in 2 minutes instead of 20.

#### 3. OAuth 2.1 Bearer Token Middleware (`src/middleware/auth.ts`)
- **Added:** A reusable Express middleware that reads `APIDASH_MCP_TOKEN` from the environment. If unset, all requests pass through. If set, every `POST /mcp` request must carry a matching `Authorization: Bearer <token>` header or receive `401 Unauthorized`.
- **Why:** Moves authentication to the network edge. Tools never execute if the client is unauthenticated. This implements the MCP November 2025 OAuth 2.1 spec requirement.

> **In Plain Terms:** This is the "bouncer at the door." If the environment variable is not set, everyone gets in freely (useful in local development). Once the token is set in production, any agent without the matching secret password is bounced immediately — it never even reaches a tool handler.

```typescript
// Applied as: app.use('/mcp', bearerAuth)
export function bearerAuth(req, res, next) {
  const token = process.env.APIDASH_MCP_TOKEN;
  if (!token) return next();
  const auth = req.headers['authorization'] || '';
  if (!auth.startsWith('Bearer ') || auth.slice(7) !== token)
    return res.status(401).json({ error: 'Unauthorized' });
  next();
}
```

##### When Does Authentication Fail? (`401 Unauthorized`)

The middleware returns a `401` error in exactly three scenarios:

| Failure Scenario | Cause |
|---|---|
| **No-ID Fail** | Request arrives with no `Authorization` header at all |
| **Wrong Format Fail** | Header exists but does not start with `Bearer ` (note: space is mandatory) |
| **Wrong Password Fail** | Header format is correct but the token string does not exactly match `APIDASH_MCP_TOKEN` |



#### 4. MCP Server Discovery Card (`src/routes/wellKnown.ts`)
- **Added:** `GET /.well-known/mcp` — returns the server's name, protocol version, capabilities, and endpoint.
- **Why:** The MCP March 2026 Roadmap adopts standard discovery routes analogous to `/.well-known/openid-configuration`. Agentic clients can query capabilities without an active connection, enabling zero-config integration in Claude Desktop, VS Code Copilot, and registry tooling.

> **In Plain Terms:** This is the server's public "business card." Modern AI tools can read this card and automatically know how to connect, what protocol to speak, and what features are available — without a human having to manually type in settings.

```json
{
  "name": "apidash-mcp",
  "protocolVersion": "2025-11-25",
  "capabilities": { "tools": {}, "resources": {}, "prompts": {} },
  "endpoint": "/mcp",
  "transport": "streamable-http"
}
```

#### 5. Tool Safety Annotations (`src/tools/annotations.ts`)
- **Added:** Per-tool `ToolAnnotations` objects — `readOnlyHint`, `destructiveHint`, `idempotentHint`, `openWorldHint` — for all 13 tools.
- **Why (MCP Blog March 16 2026):** AI models use these hints to decide whether to ask for user confirmation. For example, `http-send-request` carries `destructiveHint: true, openWorldHint: true`, signalling to Claude that this action reaches out to the real world and may not be reversible. `explore-collections` carries `readOnlyHint: true`, allowing the LLM to call it freely with no confirmation needed.

> **In Plain Terms:** These are "Warning Labels" on each tool that tell the AI exactly how dangerous it is.
> - `readOnlyHint: true` → The AI can run this freely with no confirmation (e.g., browsing a list of saved requests).
> - `destructiveHint: true` → The AI **must stop and ask the user** before executing (e.g., sending an HTTP request that could modify real data on an external server).
> - `openWorldHint: true` → The tool reaches out to the internet; its effects are unpredictable.

```typescript
"http-send-request":            { readOnlyHint: false, destructiveHint: true,  openWorldHint: true  },
"explore-collections":          { readOnlyHint: true,  destructiveHint: false, openWorldHint: false },
"update-environment-variables": { readOnlyHint: false, destructiveHint: true,  idempotentHint: true, openWorldHint: false },
```

#### 6. Granular Output Schemas (`src/tools/schemas.ts`)
- **Added:** Explicit JSON Schema `outputSchema` for every tool, matching the exact shape of each tool's `structuredContent` return value.
- **Why (MCP spec rev 2025-06-18):** Without output schemas, the LLM must guess what fields a tool returns, leading to hallucinated field names in chained tool calls. With them, the model knows exactly that `ai-llm-request` returns `{ model, duration, content, inputTokens, outputTokens, totalTokens, finishReason }` — enabling safe, accurate agent reasoning chains.

> **In Plain Terms:** Without this, an AI might guess the name of a return field and get it wrong (hallucination). For example, it might look for `response_body` when the real field is called `body`. Now the AI knows the *exact* shape of every tool's response, making multi-step reasoning chains dramatically more reliable.

---

### Summary

This architectural evolution transforms the APIDash MCP server from an experimental single-file prototype into a professional-grade, secure, and agent-friendly toolset. Each change maps directly to an official MCP specification requirement or roadmap milestone — making the server a first-class citizen in the 2025–2026 agentic ecosystem.

| Change | Standard Addressed |
|---|---|
| Per-request server factory | Stateless transport compliance |
| OAuth 2.1 middleware | MCP Nov 2025 security spec |
| `/.well-known/mcp` card | MCP March 2026 Roadmap |
| Tool annotations | MCP Blog March 16 2026 |
| Output schemas | MCP spec rev 2025-06-18 |

### SDK Version

`@modelcontextprotocol/sdk` was bumped from `^1.25.2` to `^1.29.0` to access the `ToolAnnotations` type and `outputSchema` field added in the 2025 November and June 2025 protocol revisions.

---


## Streamable Debugging (MCP Inspector)

```bash
# Inspect HTTP transport live
npm run inspector:http
# → Opens Inspector UI at http://localhost:5173
# → Connected to: http://localhost:3001/mcp

# Inspect stdio transport
npx @modelcontextprotocol/inspector -- npx tsx src/index.ts --stdio
```

The Inspector lets you:
- Browse all 13 registered tools and their Zod-validated input schemas
- Browse all 6 SEP-1865 resource URIs and preview their HTML content
- Execute tools manually and inspect raw JSON-RPC payloads
- Verify SHA-256 Hash Gate signatures are accepting calls correctly

---

## Installation & Development Features

### CLI E2E Test Suite (`test_cli.sh`)
A bash integration test suite covering **25 test scenarios** across every command path:

| Section | Tests |
|---|---|
| Saved-request commands | `help`, `info`, `langs`, `list`, `run` (by index + by ID), `codegen` (4 languages), `set` + `env` with secret masking |
| Ad-hoc HTTP | GET 200, GET response body, POST 201, `--codegen` flag, `--save` flag, DELETE, multi-header |
| Ad-hoc GraphQL | Basic query, query with variable, `--save` flag |
| AI (error paths) | Auth failure graceful exit (no crash), missing `--prompt` usage hint |
| Providers | Lists openai, groq, ollama, gemini |
| Save command | GET + POST with body + header, appears in `list` |
| Error handling | Unknown command, missing ID, missing URL, missing `--query` |

```bash
cd packages/apidash_cli
chmod +x test_cli.sh
./test_cli.sh
# → Prints: Tests: 25   ✅ Passed: 25   ❌ Failed: 0
```

---

4. Weekly Timeline:

| Weeks | Deliverables |
|---|---|
| **1–2** | Finalize monorepo structure; confirm `apidash_mcp_core` build resolves as `"@apidash/mcp-core": "file:../apidash_mcp_core"` in both consumers; write `pubspec`-equivalent monorepo docs |
| **3–4** | Implement Dart `McpSyncService`: Riverpod → JSON serialiser with 200 ms debounce, `fs.watch()` listener, schema validation, and Riverpod hydration; write Dart unit tests |
| **5–6** | Harden `@apidash/mcp-core` executors: add retry logic to `executor.ts`, streaming-response support to `ai.ts`, and expand `codegen.ts` to a 15th generator (Swift `URLSession`); increase `test_cli.sh` to 40 scenarios |
| **7–8** | Implement Express `StreamableHTTPServerTransport`, `StdioServerTransport`, and SSE endpoint; boot SHA-256 `ToolHashRegistry`; verify all 13 tools pass Claude Desktop and VS Code Copilot live sessions |
| **9–10** | Integration phase: wire `McpSyncService` bidirectional write-back into the Flutter `RequestModelNotifier` and `EnvModelNotifier` providers; resolve race conditions via mutex debounce; add integration test in Flutter |
| **11–12** | CI/CD: add GitHub Actions workflow running `test_cli.sh` on every PR; write `test_mcp_server.sh` for server-side JSON-RPC contract tests; final PR polish, README, and CHANGELOG |
