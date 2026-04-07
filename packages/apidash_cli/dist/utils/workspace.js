/**
 * APIDash CLI — Workspace utility
 * Reads and writes the shared apidash_mcp_workspace.json that is
 * maintained by the Flutter McpSyncService.
 */
import fs from "fs";
import os from "os";
import path from "path";
import { SAMPLE_REQUESTS } from "../data/api-data.js";
// ─────────────────────────────────────────────────────────────
// Path resolution (cross-platform)
// ─────────────────────────────────────────────────────────────
export function getSyncFilePath() {
    const custom = process.env.MCP_WORKSPACE_PATH;
    if (custom)
        return custom;
    const home = os.homedir();
    const platform = os.platform();
    if (platform === "linux") {
        // XDG-compliant path used by APIDash Flutter
        return path.join(home, ".local", "share", "apidash", "apidash_mcp_workspace.json");
    }
    else if (platform === "darwin") {
        return path.join(home, "Library", "Application Support", "apidash", "apidash_mcp_workspace.json");
    }
    else if (platform === "win32") {
        const appData = process.env.APPDATA || home;
        return path.join(appData, "apidash", "apidash_mcp_workspace.json");
    }
    // Generic fallback
    return path.join(home, ".apidash", "apidash_mcp_workspace.json");
}
// ─────────────────────────────────────────────────────────────
// Read
// ─────────────────────────────────────────────────────────────
export function getMcpWorkspaceData() {
    const syncFile = getSyncFilePath();
    try {
        if (fs.existsSync(syncFile)) {
            const raw = fs.readFileSync(syncFile, "utf8");
            const parsed = JSON.parse(raw);
            if (parsed?.requests && Array.isArray(parsed.requests)) {
                const mappedRequests = parsed.requests.map((r) => ({
                    id: r.id ?? String(Math.random()),
                    name: r.name ?? "Unnamed Request",
                    method: (r.method ?? "GET").toUpperCase(),
                    url: r.url ?? "",
                    description: r.description ?? "",
                    headers: r.headers,
                    body: r.body,
                }));
                return {
                    requests: mappedRequests.length > 0 ? mappedRequests : SAMPLE_REQUESTS,
                    environments: parsed.environments ?? [],
                    lastUpdated: parsed.lastUpdated,
                };
            }
        }
    }
    catch (err) {
        // Swallow and fall through to sample data
    }
    return { requests: SAMPLE_REQUESTS, environments: [] };
}
// ─────────────────────────────────────────────────────────────
// Write
// ─────────────────────────────────────────────────────────────
export function updateMcpWorkspaceData(patch) {
    const syncFile = getSyncFilePath();
    try {
        let current = { requests: [], environments: [] };
        if (fs.existsSync(syncFile)) {
            current = JSON.parse(fs.readFileSync(syncFile, "utf8"));
        }
        const updated = {
            ...current,
            ...patch,
            lastUpdated: new Date().toISOString(),
        };
        fs.mkdirSync(path.dirname(syncFile), { recursive: true });
        fs.writeFileSync(syncFile, JSON.stringify(updated, null, 2), "utf8");
        return true;
    }
    catch (err) {
        return false;
    }
}
//# sourceMappingURL=workspace.js.map