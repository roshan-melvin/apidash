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
export declare function createMcpServer(): McpServer;
