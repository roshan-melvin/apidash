import { Request, Response, NextFunction } from "express";
/**
 * MCP Bearer-token gate.
 *
 * Mode is determined by env vars at startup:
 *
 *  • APIDASH_MCP_AUTH=true   → Full OAuth 2.1 enforcement.
 *                               Only tokens issued by POST /token are accepted.
 *                               Clients must do the Dynamic Registration → PKCE flow.
 *
 *  • APIDASH_MCP_TOKEN=<str>  → Legacy static pre-shared secret (backwards compat).
 *                               Any request with Authorization: Bearer <str> is accepted.
 *                               Also accepts dynamically-issued OAuth tokens.
 *
 *  • (neither set)            → Open access — no authentication required.
 *                               Appropriate for local development.
 *
 * The OAuth endpoints (/register, /authorize, /token) are ALWAYS public
 * and are mounted before this middleware in index.ts.
 */
export declare function bearerAuth(req: Request, res: Response, next: NextFunction): void;
