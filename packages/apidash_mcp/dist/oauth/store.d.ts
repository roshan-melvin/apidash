/**
 * OAuth 2.1 In-Memory Store with Disk Persistence for Clients
 *
 * Clients are persisted to .oauth-clients.json so registered client_ids
 * survive server restarts (VS Code stores its client_id permanently).
 *
 * Auth codes and tokens remain in-memory only (short-lived by design).
 */
export interface OAuthClient {
    client_id: string;
    client_secret?: string;
    redirect_uris: string[];
    client_name?: string;
    grant_types: string[];
    response_types: string[];
    token_endpoint_auth_method: string;
    scope?: string;
    created_at: number;
}
export interface AuthCode {
    code: string;
    client_id: string;
    redirect_uri: string;
    code_challenge: string;
    code_challenge_method: "S256" | "plain";
    scope: string;
    expires_at: number;
}
export interface AccessToken {
    token: string;
    client_id: string;
    scope: string;
    expires_at: number;
    refresh_token?: string;
}
export interface RefreshToken {
    token: string;
    client_id: string;
    scope: string;
}
export declare function registerClient(data: Partial<OAuthClient>): OAuthClient;
export declare function getClient(client_id: string): OAuthClient | undefined;
export declare function createAuthCode(data: Omit<AuthCode, "code" | "expires_at">): AuthCode;
/** Atomically consume (read + delete) an auth code. Returns null if missing/expired. */
export declare function consumeAuthCode(code: string): AuthCode | null;
export declare function createAccessToken(data: Omit<AccessToken, "token" | "expires_at">): AccessToken;
export declare function validateAccessToken(token: string): AccessToken | null;
/** One-time-use: consume refresh token and return its data. */
export declare function consumeRefreshToken(token: string): RefreshToken | null;
export declare function revokeToken(token: string): boolean;
