import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpRequestContext {
  final String method;
  final String url;
  final Map<String, String>? headers;
  final String? body;
  final int? timeoutMs;

  HttpRequestContext({
    required this.method,
    required this.url,
    this.headers,
    this.body,
    this.timeoutMs,
  });
}

Future<Map<String, dynamic>> executeHttpRequest(HttpRequestContext context) async {
  final startTime = DateTime.now().millisecondsSinceEpoch;
  final finalHeaders = <String, String>{};
  if (context.headers != null) {
    finalHeaders.addAll(context.headers!);
  }

  try {
    if (context.body != null && !finalHeaders.keys.any((k) => k.toLowerCase() == 'content-type')) {
      final trimmed = context.body!.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) || (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        finalHeaders['Content-Type'] = 'application/json';
      } else {
        finalHeaders['Content-Type'] = 'text/plain';
      }
    }

    final request = http.Request(context.method, Uri.parse(context.url));
    request.headers.addAll(finalHeaders);
    if (context.body != null) {
      request.body = context.body!;
    }
    
    final timeout = Duration(milliseconds: context.timeoutMs ?? 30000);
    
    final streamedResponse = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamedResponse);
    final duration = DateTime.now().millisecondsSinceEpoch - startTime;
    final status = response.statusCode;
    final statusText = response.reasonPhrase ?? "";
    
    String responseBody;
    try {
      final decoded = jsonDecode(response.body);
      responseBody = JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      responseBody = response.body;
    }

    return {
      'success': true,
      'data': {
        'method': context.method,
        'url': context.url,
        'status': status,
        'statusText': statusText,
        'headers': response.headers,
        'body': responseBody,
        'duration': duration,
        'request': {
          'method': context.method,
          'url': context.url,
          'headers': context.headers ?? <String, String>{},
          'body': context.body,
        },
      }
    };
  } catch (err) {
    final duration = DateTime.now().millisecondsSinceEpoch - startTime;
    final msg = err.toString();
    return {
      'success': false,
      'errorMsg': msg,
      'data': {
        'method': context.method,
        'url': context.url,
        'error': msg,
        'duration': duration,
        'status': 0,
        'statusText': "Network Error",
      }
    };
  }
}
