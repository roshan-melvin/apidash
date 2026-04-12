class CodeGenInput {
  final String method;
  final String url;
  final Map<String, String>? headers;
  final String? body;
  final String? contentType;

  CodeGenInput({
    required this.method,
    required this.url,
    this.headers,
    this.body,
    this.contentType,
  });
}

const supportedGenerators = [
  "curl", "python-requests", "javascript-fetch", "javascript-axios",
  "nodejs-fetch", "dart-http", "go-http", "java-http",
  "kotlin-okhttp", "php-curl", "ruby-net", "rust-reqwest"
];

String _sanitizeUrl(String url) {
  return url.replaceAll("'", "\\'");
}

String generateCurl(CodeGenInput input) {
  final lines = ["curl -X ${input.method} '${_sanitizeUrl(input.url)}'"];
  input.headers?.forEach((k, v) {
    lines.add("  -H '$k: $v'");
  });
  if (input.body != null && input.body!.isNotEmpty) {
    lines.add("  --data '${input.body!.replaceAll("'", "\\'")}'");
  }
  return lines.join(" \\\n");
}

String generatePythonRequests(CodeGenInput input) {
  final lines = ["import requests", "", "url = \"${input.url}\""];
  if (input.headers != null && input.headers!.isNotEmpty) {
    lines.add("headers = {");
    input.headers!.forEach((k, v) {
      lines.add("    \"$k\": \"$v\",");
    });
    lines.add("}");
  } else {
    lines.add("headers = {}");
  }

  if (input.body != null && input.body!.isNotEmpty) {
    lines.addAll([
      "",
      "payload = '''${input.body}'''",
      "",
      "response = requests.${input.method.toLowerCase()}(url, headers=headers, data=payload)"
    ]);
  } else {
    lines.addAll([
      "",
      "response = requests.${input.method.toLowerCase()}(url, headers=headers)"
    ]);
  }
  lines.addAll([
    "print(response.status_code)",
    "print(response.json())"
  ]);
  return lines.join("\n");
}

String generateJavaScriptFetch(CodeGenInput input) {
  final lines = ["const response = await fetch(\"${input.url}\", {", "  method: \"${input.method}\","];
  if (input.headers != null && input.headers!.isNotEmpty) {
    lines.add("  headers: {");
    input.headers!.forEach((k, v) {
      lines.add("    \"$k\": \"$v\",");
    });
    lines.add("  },");
  }
  if (input.body != null && input.body!.isNotEmpty) {
    final escaped = input.body!.replaceAll('\\', '\\\\').replaceAll('`', '\\`').replaceAll('\${', '\\\${');
    lines.add("  body: `$escaped`,");
  }
  lines.addAll([
    "});",
    "",
    "const data = await response.json();",
    "console.log(data);"
  ]);
  return lines.join("\n");
}

String generateJavaScriptAxios(CodeGenInput input) {
  final lines = ["import axios from \"axios\";", "", "const config = {", "  method: \"${input.method.toLowerCase()}\",", "  url: \"${input.url}\","];
  if (input.headers != null && input.headers!.isNotEmpty) {
    lines.add("  headers: {");
    input.headers!.forEach((k, v) {
      lines.add("    \"$k\": \"$v\",");
    });
    lines.add("  },");
  }
  if (input.body != null && input.body!.isNotEmpty) {
    lines.add("  data: ${input.body},");
  }
  lines.addAll([
    "};",
    "",
    "const { data } = await axios(config);",
    "console.log(data);"
  ]);
  return lines.join("\n");
}

String generateNodeFetch(CodeGenInput input) {
  final lines = ["const fetch = require(\"node-fetch\");", "", "async function run() {", "  const response = await fetch(\"${input.url}\", {", "    method: \"${input.method}\","];
  if (input.headers != null && input.headers!.isNotEmpty) {
    lines.add("    headers: {");
    input.headers!.forEach((k, v) {
      lines.add("      \"$k\": \"$v\",");
    });
    lines.add("    },");
  }
  if (input.body != null && input.body!.isNotEmpty) {
    lines.add("    body: JSON.stringify(${input.body}),");
  }
  lines.addAll([
    "  });",
    "  const data = await response.json();",
    "  console.log(data);",
    "}",
    "run();"
  ]);
  return lines.join("\n");
}

String generateDartHttp(CodeGenInput input) {
  final lines = ["import 'package:http/http.dart' as http;", "", "void main() async {", "  final uri = Uri.parse('${input.url}');"];
  bool hasHeaders = input.headers != null && input.headers!.isNotEmpty;
  if (hasHeaders) {
    lines.add("  final headers = {");
    input.headers!.forEach((k, v) {
      lines.add("    '$k': '$v',");
    });
    lines.add("  };");
  }
  if (input.body != null && input.body!.isNotEmpty) {
    lines.addAll([
      "  final body = '''${input.body}''';",
      "  final response = await http.${input.method.toLowerCase()}(uri, headers: ${hasHeaders ? 'headers' : '{}'}, body: body);"
    ]);
  } else {
    lines.add("  final response = await http.${input.method.toLowerCase()}(uri${hasHeaders ? ', headers: headers' : ''});");
  }
  lines.addAll([
    "  print(response.statusCode);",
    "  print(response.body);",
    "}"
  ]);
  return lines.join("\n");
}

String generateGo(CodeGenInput input) {
  final lines = [
    "package main", "",
    "import (", "  \"fmt\"", "  \"io\"", "  \"net/http\"", "  \"strings\"", ")", "",
    "func main() {"
  ];
  if (input.body != null && input.body!.isNotEmpty) {
    lines.addAll([
      "  payload := strings.NewReader(`${input.body}`)",
      "  req, _ := http.NewRequest(\"${input.method}\", \"${input.url}\", payload)"
    ]);
  } else {
    lines.add("  req, _ := http.NewRequest(\"${input.method}\", \"${input.url}\", nil)");
  }
  input.headers?.forEach((k, v) {
    lines.add("  req.Header.Add(\"$k\", \"$v\")");
  });
  lines.addAll([
    "  client := &http.Client{}",
    "  resp, _ := client.Do(req)",
    "  defer resp.Body.Close()",
    "  body, _ := io.ReadAll(resp.Body)",
    "  fmt.Println(resp.StatusCode)",
    "  fmt.Println(string(body))",
    "}"
  ]);
  return lines.join("\n");
}

String generateJava(CodeGenInput input) {
  final lines = [
    "import java.net.URI;",
    "import java.net.http.HttpClient;",
    "import java.net.http.HttpRequest;",
    "import java.net.http.HttpResponse;",
    "",
    "public class ApiRequest {",
    "  public static void main(String[] args) throws Exception {",
    "    var client = HttpClient.newHttpClient();",
    "    var request = HttpRequest.newBuilder()",
    "        .uri(URI.create(\"${input.url}\"))"
  ];
  input.headers?.forEach((k, v) {
    lines.add("        .header(\"$k\", \"$v\")");
  });
  if (input.body != null && input.body!.isNotEmpty) {
    final method = input.method;
    lines.add("        .$method(HttpRequest.BodyPublishers.ofString(\"\"\"${input.body}\"\"\"))");
  } else {
    lines.add("        .${input.method}(HttpRequest.BodyPublishers.noBody())");
  }
  lines.addAll([
    "        .build();",
    "    var response = client.send(request, HttpResponse.BodyHandlers.ofString());",
    "    System.out.println(response.statusCode());",
    "    System.out.println(response.body());",
    "  }",
    "}"
  ]);
  return lines.join("\n");
}

String generateKotlin(CodeGenInput input) {
  final lines = ["import okhttp3.OkHttpClient", "import okhttp3.Request", ""];
  if (input.body != null && input.body!.isNotEmpty) {
    lines.addAll([
      "import okhttp3.RequestBody.Companion.toRequestBody",
      "import okhttp3.MediaType.Companion.toMediaType",
      ""
    ]);
  }
  lines.add("val client = OkHttpClient()");
  if (input.body != null && input.body!.isNotEmpty) {
    lines.add("val body = \"\"\"${input.body}\"\"\".toRequestBody(\"application/json\".toMediaType())");
  }
  lines.addAll([
    "val request = Request.Builder()",
    "    .url(\"${input.url}\")"
  ]);
  input.headers?.forEach((k, v) {
    lines.add("    .addHeader(\"$k\", \"$v\")");
  });
  if (input.body != null && input.body!.isNotEmpty) {
    lines.add("    .${input.method.toLowerCase()}(body)");
  } else {
    lines.add("    .${input.method.toLowerCase()}()");
  }
  lines.addAll([
    "    .build()",
    "",
    "val response = client.newCall(request).execute()",
    "println(response.code)",
    "println(response.body?.string())"
  ]);
  return lines.join("\n");
}

String generatePhp(CodeGenInput input) {
  final lines = ["<?php", "", "\$ch = curl_init(\"${input.url}\");", "curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, true);", "curl_setopt(\$ch, CURLOPT_CUSTOMREQUEST, \"${input.method}\");"];
  if (input.headers != null && input.headers!.isNotEmpty) {
    lines.add("curl_setopt(\$ch, CURLOPT_HTTPHEADER, [");
    input.headers!.forEach((k, v) {
      lines.add("  \"$k: $v\",");
    });
    lines.add("]);");
  }
  if (input.body != null && input.body!.isNotEmpty) {
    lines.add("curl_setopt(\$ch, CURLOPT_POSTFIELDS, '${input.body!.replaceAll("'", "\\'")}');");
  }
  lines.addAll([
    "",
    "\$response = curl_exec(\$ch);",
    "\$statusCode = curl_getinfo(\$ch, CURLINFO_HTTP_CODE);",
    "curl_close(\$ch);",
    "",
    "echo \$statusCode . \"\\n\";",
    "echo \$response . \"\\n\";"
  ]);
  return lines.join("\n");
}

String generateRuby(CodeGenInput input) {
  final lines = ["require \"net/http\"", "require \"uri\"", "", "uri = URI(\"${input.url}\")", "http = Net::HTTP.new(uri.host, uri.port)", "http.use_ssl = true if uri.scheme == \"https\"", ""];
  final m = input.method;
  final methodClass = m.substring(0, 1).toUpperCase() + m.substring(1).toLowerCase();
  lines.add("request = Net::HTTP::$methodClass.new(uri)");
  input.headers?.forEach((k, v) {
    lines.add("request[\"$k\"] = \"$v\"");
  });
  if (input.body != null && input.body!.isNotEmpty) {
    lines.add("request.body = '${input.body!.replaceAll("'", "\\'")}'");
  }
  lines.addAll([
    "",
    "response = http.request(request)",
    "puts response.code",
    "puts response.body"
  ]);
  return lines.join("\n");
}

String generateRust(CodeGenInput input) {
  final lines = [
    "use reqwest;",
    "",
    "#[tokio::main]",
    "async fn main() -> Result<(), reqwest::Error> {",
    "    let client = reqwest::Client::new();",
    "    let response = client.${input.method.toLowerCase()}(\"${input.url}\")"
  ];
  input.headers?.forEach((k, v) {
    lines.add("        .header(\"$k\", \"$v\")");
  });
  if (input.body != null && input.body!.isNotEmpty) {
    lines.add("        .body(r#\"${input.body}\"#)");
  }
  lines.addAll([
    "        .send()",
    "        .await?;",
    "",
    "    println!(\"{}\", response.status());",
    "    let text = response.text().await?;",
    "    println!(\"{}\", text);",
    "    Ok(())",
    "}"
  ]);
  return lines.join("\n");
}

String generateCode(String generatorId, CodeGenInput input) {
  switch (generatorId) {
    case 'curl': return generateCurl(input);
    case 'python-requests': return generatePythonRequests(input);
    case 'javascript-fetch': return generateJavaScriptFetch(input);
    case 'javascript-axios': return generateJavaScriptAxios(input);
    case 'nodejs-fetch': return generateNodeFetch(input);
    case 'dart-http': return generateDartHttp(input);
    case 'go-http': return generateGo(input);
    case 'java-http': return generateJava(input);
    case 'kotlin-okhttp': return generateKotlin(input);
    case 'php-curl': return generatePhp(input);
    case 'ruby-net': return generateRuby(input);
    case 'rust-reqwest': return generateRust(input);
    default: return generateCurl(input);
  }
}
