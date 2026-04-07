import axios from "axios";
import { STATUS_REASONS } from "./data/api-data.js";

export interface HttpRequestContext {
  method: string;
  url: string;
  headers?: Record<string, string>;
  body?: string;
  timeoutMs?: number;
}

export async function executeHttpRequest({ method, url, headers, body, timeoutMs }: HttpRequestContext) {
  const startTime = Date.now();
  try {
    const response = await axios({
      method: method.toLowerCase(),
      url,
      headers: (headers ?? {}) as Record<string, string>,
      data: body,
      timeout: timeoutMs ?? 30000,
      validateStatus: () => true, // don't throw on non-2xx
      maxRedirects: 10,
    });
    const duration = Date.now() - startTime;
    const status = response.status;
    const statusText = STATUS_REASONS[status] || response.statusText || "";

    let responseBody: string;
    if (typeof response.data === "object") {
      responseBody = JSON.stringify(response.data, null, 2);
    } else {
      responseBody = String(response.data ?? "");
    }

    return {
      success: true,
      data: {
        method,
        url,
        status,
        statusText,
        headers: JSON.parse(JSON.stringify(response.headers || {})),
        body: responseBody,
        duration,
        request: { method, url, headers: headers ?? {}, body },
      }
    };
  } catch (err: unknown) {
    const duration = Date.now() - startTime;
    const msg = err instanceof Error ? err.message : String(err);
    return {
      success: false,
      errorMsg: msg,
      data: {
        method, url, error: msg, duration,
        status: 0, statusText: "Network Error",
      }
    };
  }
}
