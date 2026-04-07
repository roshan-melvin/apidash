/**
 * APIDash CLI — Workspace utility
 * Reads and writes the shared apidash_mcp_workspace.json that is
 * maintained by the Flutter McpSyncService.
 */
export declare function getSyncFilePath(): string;
export interface WorkspaceRequest {
    id: string;
    name: string;
    method: string;
    url: string;
    description?: string;
    headers?: Record<string, string>;
    body?: string;
}
export interface WorkspaceEnvVariable {
    key: string;
    value: string;
    secret?: boolean;
    enabled?: boolean;
}
export interface WorkspaceEnvironment {
    id: string;
    name: string;
    values: WorkspaceEnvVariable[];
}
export interface WorkspaceData {
    requests: WorkspaceRequest[];
    environments: WorkspaceEnvironment[];
    lastUpdated?: string;
}
export declare function getMcpWorkspaceData(): WorkspaceData;
export declare function updateMcpWorkspaceData(patch: Partial<WorkspaceData>): boolean;
//# sourceMappingURL=workspace.d.ts.map