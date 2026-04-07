/**
 * APIDash CLI — GraphQL Executor
 * Sends GraphQL queries/mutations over HTTP POST.
 * Supports variables, operation names, and custom headers.
 */
export interface GraphQLRequestContext {
    url: string;
    query: string;
    variables?: Record<string, unknown>;
    operationName?: string;
    headers?: Record<string, string>;
    timeoutMs?: number;
}
export interface GraphQLResponseData {
    url: string;
    status: number;
    statusText: string;
    headers: Record<string, string>;
    body: string;
    data?: unknown;
    errors?: unknown[];
    duration: number;
}
export interface GraphQLResult {
    success: boolean;
    data: GraphQLResponseData;
    errorMsg?: string;
}
export declare function executeGraphQLRequest(ctx: GraphQLRequestContext): Promise<GraphQLResult>;
