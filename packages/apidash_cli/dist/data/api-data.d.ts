/**
 * APIDash CLI — Static fallback data
 * Used when no apidash_mcp_workspace.json is found on the filesystem.
 */
export declare const STATUS_REASONS: Record<number, string>;
export interface SampleRequest {
    id: string;
    name: string;
    method: string;
    url: string;
    description: string;
    headers?: Record<string, string>;
    body?: string;
}
export declare const SAMPLE_REQUESTS: SampleRequest[];
//# sourceMappingURL=api-data.d.ts.map