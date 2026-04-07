/**
 * createMcpServer() — per-request McpServer factory
 *
 * Creates a fully configured McpServer instance on every call.
 * This gives stateless transport compliance: no shared mutable state
 * bleeds between HTTP requests or SSE connections.
 *
 * All 6 resources and 13 tools are registered here verbatim from the
 * original index.ts.  ToolAnnotations and outputSchema are spread in
 * from the centralised src/tools/ modules.
 */
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { executeHttpRequest, executeGraphQLRequest, executeAIRequest, generateCode, getMcpWorkspaceData, updateMcpWorkspaceData, } from "@apidash/mcp-core";
import { REQUEST_BUILDER_UI } from "./ui/request-builder.js";
import { RESPONSE_VIEWER_UI } from "./ui/response-viewer.js";
import { COLLECTIONS_EXPLORER_UI } from "./ui/collections-explorer.js";
import { GRAPHQL_EXPLORER_UI } from "./ui/graphql-explorer.js";
import { CODE_GENERATOR_UI } from "./ui/code-generator.js";
import { ENV_MANAGER_UI } from "./ui/env-manager.js";
import { STATUS_REASONS } from "./data/api-data.js";
import { TOOL_ANNOTATIONS } from "./tools/annotations.js";
import { TOOL_OUTPUT_SCHEMAS } from "./tools/schemas.js";
// ─────────────────────────────────────────────────────────────
// Constants (shared with index.ts via re-export is not needed —
// index.ts keeps its own copy for the startup console output)
// ─────────────────────────────────────────────────────────────
const MIME = "text/html;profile=mcp-app";
const URI = "ui://apidash-mcp";
const SERVER_NAME = "apidash-mcp";
// ─────────────────────────────────────────────────────────────
// Helper: build the options object for a tool with annotations
// and outputSchema automatically merged in.
// ─────────────────────────────────────────────────────────────
function toolOpts(name, opts) {
    return {
        ...opts,
        annotations: TOOL_ANNOTATIONS[name],
        outputSchema: TOOL_OUTPUT_SCHEMAS[name],
    };
}
// ─────────────────────────────────────────────────────────────
// Factory
// ─────────────────────────────────────────────────────────────
export function createMcpServer() {
    const server = new McpServer({ name: SERVER_NAME, version: "1.0.0" });
    // ═══════════════════════════════════════════════════════════
    // RESOURCES (UI panels, SEP-1865 apps)
    // ═══════════════════════════════════════════════════════════
    // 1. HTTP Request Builder UI
    server.registerResource("request-builder-ui", `${URI}/request-builder`, {
        mimeType: MIME,
        description: "Interactive HTTP request builder with method selector, URL, params, headers, body, auth, and real-time response view",
    }, async (uri) => {
        console.log(`📱 resources/read: ${uri.href}`);
        return {
            contents: [{
                    uri: uri.href,
                    mimeType: MIME,
                    text: REQUEST_BUILDER_UI(),
                }],
        };
    });
    // 2. Response Viewer UI
    server.registerResource("response-viewer-ui", `${URI}/response-viewer`, {
        mimeType: MIME,
        description: "Rich HTTP response viewer with status code, headers table, formatted JSON body, and performance metrics",
    }, async (uri) => {
        console.log(`📱 resources/read: ${uri.href}`);
        return {
            contents: [{
                    uri: uri.href,
                    mimeType: MIME,
                    text: RESPONSE_VIEWER_UI(),
                }],
        };
    });
    // 3. Collections Explorer UI
    server.registerResource("collections-explorer-ui", `${URI}/collections-explorer`, {
        mimeType: MIME,
        description: "Browse and manage API request collections with searchable sidebar and quick-copy actions",
    }, async (uri) => {
        console.log(`📱 resources/read: ${uri.href}`);
        return {
            contents: [{
                    uri: uri.href,
                    mimeType: MIME,
                    text: COLLECTIONS_EXPLORER_UI(),
                }],
        };
    });
    // 4. GraphQL Explorer UI
    server.registerResource("graphql-explorer-ui", `${URI}/graphql-explorer`, {
        mimeType: MIME,
        description: "Interactive GraphQL explorer with query editor, variables, headers, and response viewer",
    }, async (uri) => {
        console.log(`📱 resources/read: ${uri.href}`);
        return {
            contents: [{
                    uri: uri.href,
                    mimeType: MIME,
                    text: GRAPHQL_EXPLORER_UI(),
                    _meta: {
                        ui: {
                            csp: {
                                resourceDomains: ["https://countries.trevorblades.com"],
                            },
                        },
                    },
                }],
        };
    });
    // 5. Code Generator UI
    server.registerResource("code-generator-ui", `${URI}/code-generator`, {
        mimeType: MIME,
        description: "Generate HTTP request code in 12+ languages: cURL, Python, JavaScript, Dart, Go, Java, Kotlin, PHP, Ruby, Rust and more",
    }, async (uri) => {
        console.log(`📱 resources/read: ${uri.href}`);
        return {
            contents: [{
                    uri: uri.href,
                    mimeType: MIME,
                    text: CODE_GENERATOR_UI(),
                }],
        };
    });
    // 6. Environment Variables Manager UI
    server.registerResource("env-manager-ui", `${URI}/env-manager`, {
        mimeType: MIME,
        description: "Manage API environment variables: global, development, staging, production scopes with secret masking and interpolation preview",
    }, async (uri) => {
        console.log(`📱 resources/read: ${uri.href}`);
        return {
            contents: [{
                    uri: uri.href,
                    mimeType: MIME,
                    text: ENV_MANAGER_UI(),
                }],
        };
    });
    // ═══════════════════════════════════════════════════════════
    // TOOLS — Model + App visible (open UI panels)
    // ═══════════════════════════════════════════════════════════
    // ── Tool 1: Open Request Builder ──────────────────────────
    server.registerTool("request-builder", toolOpts("request-builder", {
        description: "Open an interactive HTTP request builder UI. Allows building and sending HTTP requests with a full GUI including method selector, URL, query params, headers, body (JSON/form/text), authentication (Bearer/Basic/API Key), and response viewer.",
        _meta: {
            ui: {
                resourceUri: `${URI}/request-builder`,
                visibility: ["model", "app"],
            },
        },
    }), async () => {
        console.error("[request-builder] Tool executed");
        return {
            content: [{
                    type: "text",
                    text: "🚀 APIDash HTTP Request Builder is open. Use the interactive UI to:\n• Select HTTP method (GET, POST, PUT, PATCH, DELETE, etc.)\n• Enter the endpoint URL\n• Add query parameters, headers, and request body\n• Configure authentication (Bearer token, Basic auth, API key)\n• Click 'Send' to execute and view the response\n• Click 'Add to Chat' to share the result in context"
                }],
            structuredContent: {}
        };
    });
    // ── Tool 2: Send HTTP Request (model + app) ───────────────
    server.registerTool("http-send-request", toolOpts("http-send-request", {
        description: "Send an HTTP request and return the response. Supports all HTTP methods, custom headers, request body, and query parameters. Returns response status, headers, body, and timing. The response is displayed in the Response Viewer UI.",
        inputSchema: {
            method: z.enum(["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS", "CONNECT", "TRACE"])
                .describe("HTTP method"),
            url: z.string().describe("Full URL including protocol (e.g. https://api.example.com/users)"),
            headers: z.record(z.string(), z.string()).optional().describe("Request headers as key-value pairs"),
            body: z.string().optional().describe("Request body (JSON string, form-encoded, or plain text)"),
            timeoutMs: z.number().optional().describe("Request timeout in milliseconds (default: 30000)"),
        },
        _meta: {
            ui: {
                resourceUri: `${URI}/response-viewer`,
                visibility: ["model", "app"],
            },
        },
    }), async ({ method, url, headers, body, timeoutMs }) => {
        console.log(`🔧 [http-send-request] ${method} ${url}`);
        const res = await executeHttpRequest({ method, url, headers: headers, body, timeoutMs });
        if (res.success && res.data) {
            const responseBody = res.data.body || "";
            const duration = res.data.duration;
            return {
                content: [{
                        type: "text",
                        text: `📨 HTTP ${method} ${url}\n\n**Status:** ${res.data.status} ${res.data.statusText}\n**Duration:** ${duration}ms\n**Body size:** ${(new TextEncoder().encode(responseBody).length / 1024).toFixed(2)} KB\n\n**Response Body (preview):**\n\`\`\`json\n${responseBody.slice(0, 2000)}${responseBody.length > 2000 ? '\n... (truncated)' : ''}\n\`\`\``
                    }],
                structuredContent: res.data,
            };
        }
        else {
            console.error(`❌ [http-send-request] Error: ${res.errorMsg}`);
            return {
                content: [{
                        type: "text",
                        text: `❌ Request failed: ${res.errorMsg}\n\nMethod: ${method}\nURL: ${url}`
                    }],
                structuredContent: res.data,
            };
        }
    });
    // ── Tool 3: View Response UI ──────────────────────────────
    server.registerTool("view-response", toolOpts("view-response", {
        description: "Display an HTTP response in the rich Response Viewer UI. Shows color-coded status, formatted body (JSON/HTML/text), response headers table, and performance metrics.",
        inputSchema: {
            status: z.number().describe("HTTP status code"),
            statusText: z.string().optional().describe("HTTP status text"),
            headers: z.record(z.string(), z.string()).optional().describe("Response headers"),
            body: z.string().optional().describe("Response body"),
            method: z.string().optional().describe("HTTP method used"),
            url: z.string().optional().describe("Request URL"),
            duration: z.number().optional().describe("Request duration in ms"),
        },
        _meta: {
            ui: {
                resourceUri: `${URI}/response-viewer`,
                visibility: ["model", "app"],
            },
        },
    }), async (input) => {
        console.log(`🔧 [view-response] status=${input.status}`);
        const statusText = input.statusText || STATUS_REASONS[input.status] || "";
        const statusEmoji = input.status >= 500 ? "🔴" : input.status >= 400 ? "🟡" : input.status >= 300 ? "🔵" : "🟢";
        return {
            content: [{
                    type: "text",
                    text: `${statusEmoji} Response: ${input.status} ${statusText}${input.duration ? ` (${input.duration}ms)` : ""}`
                }],
            structuredContent: {
                response: input,
            },
        };
    });
    // ── Tool 4: Explore Collections ───────────────────────────
    server.registerTool("explore-collections", toolOpts("explore-collections", {
        description: "Open the APIDash Collections Explorer to browse saved API requests. Shows a searchable list of requests with method, URL, and description. Select to see cURL preview, body, and headers. Load into builder or add to chat context.",
        _meta: {
            ui: {
                resourceUri: `${URI}/collections-explorer`,
                visibility: ["model", "app"],
            },
        },
    }), async () => {
        console.error("[explore-collections] Tool executed");
        const workspace = getMcpWorkspaceData();
        const requests = workspace.requests;
        const summary = requests.map((r) => `• ${r.method} ${r.name}: ${r.url}`).join("\n");
        return {
            content: [{
                    type: "text",
                    text: `📁 APIDash Collections Explorer opened.\n\nAvailable requests (${requests.length}):\n${summary}\n\nUse the sidebar to browse, click to view details, and 'Load in Builder' to test.`
                }],
            structuredContent: {
                totalRequests: requests.length,
                requests: requests.map((r) => ({ id: r.id, name: r.name, method: r.method, url: r.url })),
            },
        };
    });
    // ── Tool 5: GraphQL Explorer ──────────────────────────────
    server.registerTool("graphql-explorer", toolOpts("graphql-explorer", {
        description: "Open an interactive GraphQL Explorer UI. Features a query editor, variables JSON editor, custom headers, and formatted response viewer. Pre-loaded with a sample query against the Countries API.",
        _meta: {
            ui: {
                resourceUri: `${URI}/graphql-explorer`,
                visibility: ["model", "app"],
            },
        },
    }), async () => {
        console.error("[graphql-explorer] Tool executed");
        return {
            content: [{
                    type: "text",
                    text: "⬡ APIDash GraphQL Explorer opened.\n\nFeatures:\n• Query editor with syntax hints\n• Variables editor (JSON)\n• Custom headers support\n• Formatted JSON response viewer\n• Pre-loaded sample: Countries API\n\nEnter your GraphQL endpoint URL and query, then click '▶ Run'."
                }]
        };
    });
    // ── Tool 6: Execute GraphQL (app-only) ────────────────────
    server.registerTool("graphql-execute-query", toolOpts("graphql-execute-query", {
        description: "Execute a GraphQL query against an endpoint. Returns the raw JSON response and populates the GraphQL Explorer response panel.",
        inputSchema: {
            url: z.string().describe("GraphQL endpoint URL"),
            query: z.string().describe("GraphQL query or mutation string"),
            variables: z.record(z.string(), z.unknown()).optional().describe("GraphQL variables as JSON object"),
            headers: z.record(z.string(), z.string()).optional().describe("HTTP headers"),
        },
        _meta: {
            ui: {
                resourceUri: `${URI}/graphql-explorer`,
                visibility: ["app"],
            },
        },
    }), async ({ url, query, variables, headers }) => {
        console.log(`🔧 [graphql-execute-query] ${url}`);
        const result = await executeGraphQLRequest({
            url,
            query,
            variables,
            headers: headers,
            timeoutMs: 30_000,
        });
        if (!result.success) {
            return {
                content: [{ type: "text", text: `❌ GraphQL request failed: ${result.errorMsg}` }],
                structuredContent: { error: result.errorMsg, status: 0 },
            };
        }
        const { status, duration, body, errors, data } = result.data;
        const hasErrors = errors && Array.isArray(errors) && errors.length > 0;
        return {
            content: [{
                    type: "text",
                    text: hasErrors
                        ? `❌ GraphQL errors:\n${JSON.stringify(errors, null, 2)}`
                        : `✅ GraphQL query executed (${duration}ms)\n\n${body.slice(0, 2000)}`
                }],
            structuredContent: {
                status,
                duration,
                data: data ?? JSON.parse(body),
                hasErrors,
            },
        };
    });
    // ── Tool 7: Open Code Generator UI ───────────────────────
    server.registerTool("codegen-ui", toolOpts("codegen-ui", {
        description: "Open the APIDash Code Generator UI to generate HTTP request code in your preferred language. Supports cURL, Python (requests), JavaScript (fetch/axios), Node.js, Dart, Go, Java, Kotlin, PHP, Ruby, and Rust.",
        inputSchema: {
            method: z.enum(["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]).optional()
                .describe("Pre-populate with HTTP method"),
            url: z.string().optional().describe("Pre-populate with URL"),
            headers: z.record(z.string(), z.string()).optional().describe("Pre-populate with headers"),
            body: z.string().optional().describe("Pre-populate with request body"),
        },
        _meta: {
            ui: {
                resourceUri: `${URI}/code-generator`,
                visibility: ["model", "app"],
            },
        },
    }), async ({ method, url, headers, body }) => {
        console.error("[codegen-ui] Tool executed");
        return {
            content: [{
                    type: "text",
                    text: `⚙️ APIDash Code Generator opened.\n\nSupported languages:\n• cURL, Python (requests), JavaScript (fetch & axios)\n• Node.js (fetch), Dart (http), Go, Java (HttpClient)\n• Kotlin (OkHttp), PHP (cURL), Ruby (Net::HTTP), Rust (reqwest)\n\n${method && url ? `Pre-loaded: ${method} ${url}` : "Enter request details and select a language to generate code."}`
                }],
            structuredContent: method && url
                ? { request: { method, url, headers: headers ?? {}, body } }
                : undefined,
        };
    });
    // ── Tool 8: Generate Code Snippet (app-only) ──────────────
    server.registerTool("generate-code-snippet", toolOpts("generate-code-snippet", {
        description: "Server-side code generation for HTTP requests. Returns ready-to-use code in the specified language. Called by the Code Generator UI.",
        inputSchema: {
            method: z.string().describe("HTTP method"),
            url: z.string().describe("Request URL"),
            headers: z.record(z.string(), z.string()).optional().describe("Request headers"),
            body: z.string().optional().describe("Request body"),
            generator: z.enum([
                "curl", "python-requests", "javascript-fetch", "javascript-axios",
                "nodejs-fetch", "dart-http", "go-http", "java-http",
                "kotlin-okhttp", "php-curl", "ruby-net", "rust-reqwest"
            ]).describe("Code generator to use"),
        },
        _meta: {
            ui: {
                resourceUri: `${URI}/code-generator`,
                visibility: ["app"],
            },
        },
    }), async ({ method, url, headers, body, generator }) => {
        console.log(`🔧 [generate-code-snippet] generator=${generator}, ${method} ${url}`);
        const code = generateCode(generator, {
            method,
            url,
            headers: (headers ?? {}),
            body,
        });
        return {
            content: [{ type: "text", text: `Generated ${generator} code:\n\n\`\`\`\n${code}\n\`\`\`` }],
            structuredContent: {
                generator,
                language: generator,
                code,
                request: { method, url, headers, body },
            },
        };
    });
    // ── Tool 9: Open Environment Manager UI ──────────────────
    server.registerTool("manage-environment", toolOpts("manage-environment", {
        description: "Open the APIDash Environment Variables Manager. Manage global, development, staging, and production environment variables. Supports secret masking, variable interpolation preview using {{VARIABLE_NAME}} syntax, and export.",
        _meta: {
            ui: {
                resourceUri: `${URI}/env-manager`,
                visibility: ["model", "app"],
            },
        },
    }), async () => {
        console.error("[manage-environment] Tool executed");
        return {
            content: [{
                    type: "text",
                    text: "🌱 APIDash Environment Variables Manager opened.\n\nScopes: Global, Development, Staging, Production\n\nUse {{VARIABLE_NAME}} in URLs, headers, and body to reference variables.\n\nExamples:\n• https://{{BASE_URL}}/api/{{VERSION}}/users\n• Authorization: Bearer {{TOKEN}}\n• {\"api_key\": \"{{API_KEY}}\"}"
                }]
        };
    });
    // ── Tool 10: Update Environment Variables (app-only) ──────
    server.registerTool("update-environment-variables", toolOpts("update-environment-variables", {
        description: "Update environment variables in a given scope. Called by the Environment Manager UI when saving changes.",
        inputSchema: {
            env: z.enum(["global", "development", "staging", "production"]).describe("Environment scope"),
            variables: z.array(z.object({
                key: z.string().describe("Variable name"),
                value: z.string().describe("Variable value"),
                secret: z.boolean().optional().describe("Whether this is a secret value"),
                enabled: z.boolean().optional().describe("Whether this variable is active"),
            })).describe("Array of variables to set"),
        },
        _meta: {
            ui: {
                resourceUri: `${URI}/env-manager`,
                visibility: ["app"],
            },
        },
    }), async ({ env, variables }) => {
        console.log(`🔧 [update-environment-variables] env=${env}, vars=${variables.length}`);
        const safeVars = variables.map((v) => ({
            key: v.key,
            value: v.secret ? "***" : v.value,
            secret: v.secret ?? false,
            enabled: v.enabled ?? true,
        }));
        // Save to sync file
        const workspace = getMcpWorkspaceData();
        let envIndex = workspace.environments.findIndex((e) => e.name === env);
        if (envIndex === -1) {
            workspace.environments.push({ id: env, name: env, values: variables });
        }
        else {
            workspace.environments[envIndex].values = variables;
        }
        updateMcpWorkspaceData({ environments: workspace.environments });
        return {
            content: [{
                    type: "text",
                    text: `✅ Updated ${variables.length} variable(s) in ${env} environment:\n${variables.map((v) => `• ${v.key}${v.secret ? ' (secret)' : ''}`).join('\n')}`
                }],
            structuredContent: {
                env,
                count: variables.length,
                variables: safeVars,
            },
        };
    });
    // ── Tool 11: Get API Request Template ─────────────────────
    server.registerTool("get-api-request-template", toolOpts("get-api-request-template", {
        description: "Get a pre-built API request template from the APIDash collections. Returns complete request details including method, URL, headers, body. Use this to quickly test common APIs like JSONPlaceholder, GitHub, HTTPBin.",
        inputSchema: {
            templateId: z.enum([
                "get-posts", "get-post", "create-post", "update-post", "delete-post",
                "get-users", "get-comments", "github-user", "httpbin-get", "httpbin-post"
            ]).describe("Template ID to retrieve"),
        },
        _meta: {
            ui: {
                resourceUri: `${URI}/request-builder`,
                visibility: ["model", "app"],
            },
        },
    }), async ({ templateId }) => {
        console.log(`🔧 [get-api-request-template] id=${templateId}`);
        const workspace = getMcpWorkspaceData();
        const template = workspace.requests.find((r) => r.id === templateId);
        if (!template) {
            return {
                content: [{ type: "text", text: `❌ Template '${templateId}' not found.` }]
            };
        }
        return {
            content: [{
                    type: "text",
                    text: `📋 Template: ${template.name}\n\nMethod: ${template.method}\nURL: ${template.url}\nDescription: ${template.description}${template.body ? `\n\nBody:\n${template.body}` : ""}`
                }],
            structuredContent: {
                request: template,
                action: "load-template",
            },
        };
    });
    // ── Tool 12: AI / LLM Request ─────────────────────────────
    server.registerTool("ai-llm-request", toolOpts("ai-llm-request", {
        description: "Send a chat completion request to any OpenAI-compatible LLM endpoint. Supports OpenAI, Groq, Mistral, Together AI, Ollama (local), Google Gemini, and custom endpoints. Returns the assistant reply with token usage.",
        inputSchema: {
            url: z.string().describe("LLM endpoint URL (e.g. https://api.openai.com/v1/chat/completions). Use 'openai', 'groq', 'mistral', 'ollama', 'gemini', 'together', or 'anthropic' as shorthand."),
            model: z.string().describe("Model name (e.g. gpt-4o, llama3, mixtral-8x7b-32768, gemini-pro)"),
            prompt: z.string().describe("User message / prompt to send"),
            systemPrompt: z.string().optional().describe("Optional system prompt to set context/persona"),
            apiKey: z.string().optional().describe("Bearer API key. Can also be set via APIDASH_AI_KEY env var"),
            temperature: z.number().optional().describe("Sampling temperature 0-2 (default 0.7)"),
            maxTokens: z.number().optional().describe("Maximum output tokens (default 1024)"),
            headers: z.record(z.string(), z.string()).optional().describe("Additional HTTP headers"),
        },
    }), async ({ url, model, prompt, systemPrompt, apiKey, temperature, maxTokens, headers }) => {
        console.log(`🔧 [ai-llm-request] ${url} model=${model}`);
        // Resolve URL (named provider or raw URL)
        const PROVIDERS = {
            openai: "https://api.openai.com/v1/chat/completions",
            groq: "https://api.groq.com/openai/v1/chat/completions",
            mistral: "https://api.mistral.ai/v1/chat/completions",
            together: "https://api.together.xyz/v1/chat/completions",
            ollama: "http://localhost:11434/api/chat",
            gemini: "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
            anthropic: "https://api.anthropic.com/v1/messages",
        };
        const resolvedUrl = PROVIDERS[url?.toLowerCase()] ?? url;
        const result = await executeAIRequest({
            url: resolvedUrl,
            apiKey: apiKey || process.env.APIDASH_AI_KEY || undefined,
            model,
            messages: [{ role: "user", content: prompt }],
            systemPrompt,
            temperature,
            maxTokens,
            headers: headers,
            timeoutMs: 60_000,
        });
        if (!result.success) {
            return {
                content: [{ type: "text", text: `❌ AI request failed: ${result.errorMsg}` }],
                structuredContent: { error: result.errorMsg, status: result.data?.status ?? 0 },
            };
        }
        const { status, duration, content, inputTokens, outputTokens, totalTokens, finishReason } = result.data;
        if (status >= 400) {
            return {
                content: [{ type: "text", text: `❌ AI request failed (HTTP ${status}):\n${result.data.rawBody.slice(0, 500)}` }],
                structuredContent: { status, error: JSON.parse(result.data.rawBody) },
            };
        }
        return {
            content: [{
                    type: "text",
                    text: `🤖 **${model}** responded (${duration}ms${totalTokens ? `, ${totalTokens} tokens` : ""}):\n\n${content}`,
                }],
            structuredContent: {
                model,
                duration,
                content,
                inputTokens,
                outputTokens,
                totalTokens,
                finishReason,
            },
        };
    });
    // ── Tool 13: Save Request to Workspace ────────────────────
    server.registerTool("save-request", toolOpts("save-request", {
        description: "Save a new API request (HTTP or GraphQL) to the APIDash workspace JSON file so it appears in the Collections panel and CLI. Returns the assigned request ID.",
        inputSchema: {
            name: z.string().describe("Human-readable request name"),
            method: z.enum(["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]).describe("HTTP method"),
            url: z.string().describe("Request URL"),
            headers: z.record(z.string(), z.string()).optional().describe("Request headers"),
            body: z.string().optional().describe("Request body (JSON string)"),
            description: z.string().optional().describe("Optional description"),
        },
    }), async ({ name, method, url, headers, body, description }) => {
        console.log(`🔧 [save-request] ${method} ${url} name="${name}"`);
        const { randomUUID } = await import("crypto");
        const workspace = getMcpWorkspaceData();
        const id = randomUUID().slice(0, 8);
        workspace.requests.push({ id, name, method, url, headers, body, description });
        const saved = updateMcpWorkspaceData({ requests: workspace.requests });
        if (!saved) {
            return {
                content: [{ type: "text", text: `❌ Failed to save request — workspace file not writable.` }],
                structuredContent: { success: false },
            };
        }
        return {
            content: [{
                    type: "text",
                    text: `✅ Request saved!\n\n**Name:** ${name}\n**ID:** \`${id}\`\n**Method:** ${method}\n**URL:** ${url}\n\nRun it with: \`apidash-cli run ${id}\``,
                }],
            structuredContent: { success: true, id, name, method, url },
        };
    });
    return server;
}
