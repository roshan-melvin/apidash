/**
 * OAuth 2.1 Routes (MCP spec-compliant)
 *
 * Endpoints implemented:
 *  GET  /.well-known/oauth-authorization-server  — RFC 8414 metadata discovery
 *  POST /register                                — RFC 7591 Dynamic Client Registration
 *  GET  /authorize                               — Auth code + PKCE (RFC 7636)
 *  POST /token                                   — Token endpoint (code exchange + refresh)
 *  POST /token/revoke                            — RFC 7009 token revocation
 *
 * Security notes:
 *  • PKCE S256 is REQUIRED (plain is rejected per OAuth 2.1 mandate)
 *  • All tokens are cryptographically random (base64url, 256-bit)
 *  • Auth codes are single-use with a 60 s TTL
 *  • Access tokens have a 1 hr TTL; refresh tokens are rolling one-time-use
 *  • Authorization auto-approves (appropriate for a local developer tool)
 */
declare const router: import("express-serve-static-core").Router;
export default router;
