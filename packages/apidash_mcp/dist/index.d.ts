#!/usr/bin/env node
/**
 * APIDash MCP Server — Composition Root
 *
 * Thin entry point that wires together:
 *   • Express app (CORS, JSON parsing)
 *   • bearerAuth middleware (OAuth 2.1, MCP Nov 2025)
 *   • /health and /.well-known/mcp routes
 *   • POST /mcp  (Streamable HTTP, stateless — per-request McpServer)
 *   • GET  /mcp/sse  (SSE streaming — per-request McpServer)
 *   • --stdio branch for Claude Desktop / VS Code Copilot
 *
 * All handler logic lives in src/factory.ts.
 *
 * Tools:
 *   - request-builder          → Interactive HTTP request builder UI
 *   - http-send-request        → Send an HTTP request and get response
 *   - view-response            → View last HTTP response in rich UI
 *   - explore-collections      → Browse saved API request collections
 *   - graphql-explorer         → Interactive GraphQL query UI
 *   - graphql-execute-query    → Execute a GraphQL query server-side
 *   - generate-code-snippet    → Generate code for HTTP request in any language
 *   - codegen-ui               → Open code generator UI for a request
 *   - manage-environment       → Manage API environment variables
 *   - update-environment-variables → Server-side env var update
 *   - get-api-request-template → Get a pre-built request template
 *   - ai-llm-request           → Send a chat completion request to any LLM
 *   - save-request             → Save a new request to the APIDash workspace
 *
 * Run with:  npm run dev
 * Inspect:   npm run inspector:http
 */
import "dotenv/config";
