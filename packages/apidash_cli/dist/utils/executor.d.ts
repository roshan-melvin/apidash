/**
 * APIDash CLI — HTTP Executor
 * Thin axios wrapper used by the `run` command.
 * Mirrors the executor in apidash-mcp so both tools
 * share identical HTTP semantics.
 */
export interface HttpRequestContext {
    method: string;
    url: string;
    headers?: Record<string, string>;
    body?: string;
    timeoutMs?: number;
}
export interface HttpResponseData {
    method: string;
    url: string;
    status: number;
    statusText: string;
    headers: Record<string, string>;
    body: string;
    duration: number;
    request: {
        method: string;
        url: string;
        headers: Record<string, string>;
        body?: string;
    };
}
export interface ExecuteResult {
    success: boolean;
    data: HttpResponseData;
    errorMsg?: string;
}
export declare function executeHttpRequest(ctx: HttpRequestContext): Promise<ExecuteResult>;
//# sourceMappingURL=executor.d.ts.map