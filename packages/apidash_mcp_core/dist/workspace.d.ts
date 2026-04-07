export interface WorkspaceRequest {
    id: string;
    name: string;
    method: string;
    url: string;
    headers?: Record<string, string>;
    body?: string;
    description?: string;
}
export declare function getSyncFilePath(): string;
export declare function getMcpWorkspaceData(): {
    requests: any;
    environments: any;
    lastUpdated: string | undefined;
};
export declare function updateMcpWorkspaceData(newData: any): boolean;
