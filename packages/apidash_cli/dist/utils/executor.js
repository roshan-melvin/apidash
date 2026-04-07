/**
 * APIDash CLI — HTTP Executor
 * Thin axios wrapper used by the `run` command.
 * Mirrors the executor in apidash-mcp so both tools
 * share identical HTTP semantics.
 */
import axios from "axios";
import { STATUS_REASONS } from "../data/api-data.js";
export async function executeHttpRequest(ctx) {
    const { method, url, headers, body, timeoutMs = 30_000 } = ctx;
    const startTime = Date.now();
    try {
        const response = await axios({
            method: method.toLowerCase(),
            url,
            headers: (headers ?? {}),
            data: body,
            timeout: timeoutMs,
            validateStatus: () => true, // never throw on non-2xx
            maxRedirects: 10,
        });
        const duration = Date.now() - startTime;
        const status = response.status;
        const statusText = STATUS_REASONS[status] ?? response.statusText ?? "";
        const responseBody = typeof response.data === "object"
            ? JSON.stringify(response.data, null, 2)
            : String(response.data ?? "");
        return {
            success: true,
            data: {
                method,
                url,
                status,
                statusText,
                headers: response.headers,
                body: responseBody,
                duration,
                request: { method, url, headers: headers ?? {}, body },
            },
        };
    }
    catch (err) {
        const duration = Date.now() - startTime;
        const msg = err instanceof Error ? err.message : String(err);
        return {
            success: false,
            errorMsg: msg,
            data: {
                method,
                url,
                status: 0,
                statusText: "Network Error",
                headers: {},
                body: "",
                duration,
                request: { method, url, headers: headers ?? {}, body },
            },
        };
    }
}
//# sourceMappingURL=executor.js.map