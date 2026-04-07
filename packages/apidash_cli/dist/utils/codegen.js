/**
 * APIDash CLI — Code Generator
 * Generates HTTP request snippets in 12 languages.
 * Mirrors apidash-mcp/src/utils/codegen.ts for consistency.
 */
function entries(h) {
    return Object.entries(h ?? {});
}
function q(s) {
    return s.replace(/'/g, "\\'");
}
// ── Generators ─────────────────────────────────────────────────
export function generateCurl({ method, url, headers, body }) {
    const lines = [`curl -X ${method} '${q(url)}'`];
    for (const [k, v] of entries(headers))
        lines.push(`  -H '${k}: ${v}'`);
    if (body)
        lines.push(`  --data '${q(body)}'`);
    return lines.join(" \\\n");
}
export function generatePythonRequests({ method, url, headers, body }) {
    const lines = ["import requests", "", `url = "${url}"`];
    if (headers && Object.keys(headers).length) {
        lines.push("headers = {");
        for (const [k, v] of entries(headers))
            lines.push(`    "${k}": "${v}",`);
        lines.push("}");
    }
    else {
        lines.push("headers = {}");
    }
    lines.push("");
    if (body) {
        lines.push(`payload = '''${body}'''`, "");
        lines.push(`response = requests.${method.toLowerCase()}(url, headers=headers, data=payload)`);
    }
    else {
        lines.push(`response = requests.${method.toLowerCase()}(url, headers=headers)`);
    }
    lines.push("print(response.status_code)", "print(response.json())");
    return lines.join("\n");
}
export function generateJavaScriptFetch({ method, url, headers, body }) {
    const lines = [`const response = await fetch("${url}", {`, `  method: "${method}",`];
    if (headers && Object.keys(headers).length) {
        lines.push("  headers: {");
        for (const [k, v] of entries(headers))
            lines.push(`    "${k}": "${v}",`);
        lines.push("  },");
    }
    if (body) {
        const esc = body.replace(/\\/g, "\\\\").replace(/`/g, "\\`").replace(/\${/g, "\\${");
        lines.push(`  body: \`${esc}\`,`);
    }
    lines.push("});", "", "const data = await response.json();", "console.log(data);");
    return lines.join("\n");
}
export function generateJavaScriptAxios({ method, url, headers, body }) {
    const lines = ['import axios from "axios";', "", "const config = {", `  method: "${method.toLowerCase()}",`, `  url: "${url}",`];
    if (headers && Object.keys(headers).length) {
        lines.push("  headers: {");
        for (const [k, v] of entries(headers))
            lines.push(`    "${k}": "${v}",`);
        lines.push("  },");
    }
    if (body)
        lines.push(`  data: ${body},`);
    lines.push("};", "", "const { data } = await axios(config);", "console.log(data);");
    return lines.join("\n");
}
export function generateNodeFetch({ method, url, headers, body }) {
    const lines = ['const fetch = require("node-fetch");', "", "async function run() {", `  const response = await fetch("${url}", {`, `    method: "${method}",`];
    if (headers && Object.keys(headers).length) {
        lines.push("    headers: {");
        for (const [k, v] of entries(headers))
            lines.push(`      "${k}": "${v}",`);
        lines.push("    },");
    }
    if (body)
        lines.push(`    body: JSON.stringify(${body}),`);
    lines.push("  });", "  const data = await response.json();", "  console.log(data);", "}", "run();");
    return lines.join("\n");
}
export function generateDartHttp({ method, url, headers, body }) {
    const lines = ["import 'package:http/http.dart' as http;", "", "void main() async {", `  final uri = Uri.parse('${url}');`];
    if (headers && Object.keys(headers).length) {
        lines.push("  final headers = {");
        for (const [k, v] of entries(headers))
            lines.push(`    '${k}': '${v}',`);
        lines.push("  };");
    }
    if (body) {
        lines.push(`  final body = '''${body}''';`);
        lines.push(`  final response = await http.${method.toLowerCase()}(uri, headers: ${headers ? "headers" : "{}"}, body: body);`);
    }
    else {
        lines.push(`  final response = await http.${method.toLowerCase()}(uri${headers ? ", headers: headers" : ""});`);
    }
    lines.push("  print(response.statusCode);", "  print(response.body);", "}");
    return lines.join("\n");
}
export function generateGo({ method, url, headers, body }) {
    const lines = ["package main", "", 'import (', '  "fmt"', '  "io"', '  "net/http"', '  "strings"', ")", "", "func main() {"];
    if (body) {
        lines.push(`  payload := strings.NewReader(\`${body}\`)`);
        lines.push(`  req, _ := http.NewRequest("${method}", "${url}", payload)`);
    }
    else {
        lines.push(`  req, _ := http.NewRequest("${method}", "${url}", nil)`);
    }
    for (const [k, v] of entries(headers))
        lines.push(`  req.Header.Add("${k}", "${v}")`);
    lines.push("  client := &http.Client{}");
    lines.push("  resp, _ := client.Do(req)");
    lines.push("  defer resp.Body.Close()");
    lines.push("  body, _ := io.ReadAll(resp.Body)");
    lines.push("  fmt.Println(resp.StatusCode)");
    lines.push("  fmt.Println(string(body))");
    lines.push("}");
    return lines.join("\n");
}
export function generateJava({ method, url, headers, body }) {
    const lines = [
        "import java.net.URI;", "import java.net.http.HttpClient;",
        "import java.net.http.HttpRequest;", "import java.net.http.HttpResponse;", "",
        "public class ApiRequest {",
        "  public static void main(String[] args) throws Exception {",
        "    var client = HttpClient.newHttpClient();",
        `    var request = HttpRequest.newBuilder()`, `        .uri(URI.create("${url}"))`,
    ];
    for (const [k, v] of entries(headers))
        lines.push(`        .header("${k}", "${v}")`);
    if (body) {
        lines.push(`        .${method}(HttpRequest.BodyPublishers.ofString("""${body}"""))`);
    }
    else {
        lines.push(`        .${method}(HttpRequest.BodyPublishers.noBody())`);
    }
    lines.push("        .build();");
    lines.push("    var response = client.send(request, HttpResponse.BodyHandlers.ofString());");
    lines.push("    System.out.println(response.statusCode());");
    lines.push("    System.out.println(response.body());");
    lines.push("  }", "}");
    return lines.join("\n");
}
export function generateKotlin({ method, url, headers, body }) {
    const lines = ["import okhttp3.OkHttpClient", "import okhttp3.Request", ""];
    if (body) {
        lines.push("import okhttp3.RequestBody.Companion.toRequestBody");
        lines.push("import okhttp3.MediaType.Companion.toMediaType", "");
    }
    lines.push("val client = OkHttpClient()");
    if (body)
        lines.push(`val body = """${body}""".toRequestBody("application/json".toMediaType())`);
    lines.push("val request = Request.Builder()", `    .url("${url}")`);
    for (const [k, v] of entries(headers))
        lines.push(`    .addHeader("${k}", "${v}")`);
    lines.push(body ? `    .${method.toLowerCase()}(body)` : `    .${method.toLowerCase()}()`);
    lines.push("    .build()", "", "val response = client.newCall(request).execute()");
    lines.push("println(response.code)", "println(response.body?.string())");
    return lines.join("\n");
}
export function generatePhp({ method, url, headers, body }) {
    const lines = ["<?php", "", `$ch = curl_init("${url}");`, "curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);", `curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "${method}");`];
    if (headers && Object.keys(headers).length) {
        lines.push("curl_setopt($ch, CURLOPT_HTTPHEADER, [");
        for (const [k, v] of entries(headers))
            lines.push(`  "${k}: ${v}",`);
        lines.push("]);");
    }
    if (body)
        lines.push(`curl_setopt($ch, CURLOPT_POSTFIELDS, '${q(body)}');`);
    lines.push("", "$response = curl_exec($ch);", "$statusCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);", "curl_close($ch);", "", 'echo $statusCode . "\\n";', 'echo $response . "\\n";');
    return lines.join("\n");
}
export function generateRuby({ method, url, headers, body }) {
    const lines = ['require "net/http"', 'require "uri"', "", `uri = URI("${url}")`, `http = Net::HTTP.new(uri.host, uri.port)`, 'http.use_ssl = true if uri.scheme == "https"', "", `request = Net::HTTP::${method.charAt(0) + method.slice(1).toLowerCase()}.new(uri)`];
    for (const [k, v] of entries(headers))
        lines.push(`request["${k}"] = "${v}"`);
    if (body)
        lines.push(`request.body = '${q(body)}'`);
    lines.push("", "response = http.request(request)", "puts response.code", "puts response.body");
    return lines.join("\n");
}
export function generateRust({ method, url, headers, body }) {
    const lines = ["use reqwest;", "", "#[tokio::main]", "async fn main() -> Result<(), reqwest::Error> {", "    let client = reqwest::Client::new();", `    let response = client.${method.toLowerCase()}("${url}")`];
    for (const [k, v] of entries(headers))
        lines.push(`        .header("${k}", "${v}")`);
    if (body)
        lines.push(`        .body(r#"${body}"#)`);
    lines.push('        .send()', '        .await?;', "", '    println!("{}", response.status());', "    let text = response.text().await?;", '    println!("{}", text);', "    Ok(())", "}");
    return lines.join("\n");
}
// ── Dispatcher ─────────────────────────────────────────────────
export function generateCode(id, input) {
    switch (id) {
        case "curl": return generateCurl(input);
        case "python-requests": return generatePythonRequests(input);
        case "javascript-fetch": return generateJavaScriptFetch(input);
        case "javascript-axios": return generateJavaScriptAxios(input);
        case "nodejs-fetch": return generateNodeFetch(input);
        case "dart-http": return generateDartHttp(input);
        case "go-http": return generateGo(input);
        case "java-http": return generateJava(input);
        case "kotlin-okhttp": return generateKotlin(input);
        case "php-curl": return generatePhp(input);
        case "ruby-net": return generateRuby(input);
        case "rust-reqwest": return generateRust(input);
        default: return generateCurl(input);
    }
}
export const SUPPORTED_GENERATORS = [
    "curl", "python-requests", "javascript-fetch", "javascript-axios",
    "nodejs-fetch", "dart-http", "go-http", "java-http",
    "kotlin-okhttp", "php-curl", "ruby-net", "rust-reqwest",
];
//# sourceMappingURL=codegen.js.map