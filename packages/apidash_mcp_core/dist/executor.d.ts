export interface HttpRequestContext {
    method: string;
    url: string;
    headers?: Record<string, string>;
    body?: string;
    timeoutMs?: number;
}
export declare function executeHttpRequest({ method, url, headers, body, timeoutMs }: HttpRequestContext): Promise<{
    success: boolean;
    data: {
        method: string;
        url: string;
        status: number;
        statusText: string;
        headers: any;
        body: string;
        duration: number;
        request: {
            method: string;
            url: string;
            headers: Record<string, string>;
            body: string | undefined;
        };
        error?: undefined;
    };
    errorMsg?: undefined;
} | {
    success: boolean;
    errorMsg: string;
    data: {
        method: string;
        url: string;
        error: string;
        duration: number;
        status: number;
        statusText: string;
        headers?: undefined;
        body?: undefined;
        request?: undefined;
    };
}>;
