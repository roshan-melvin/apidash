import 'dart:convert';
import 'package:http/http.dart' as http;

class GraphQLRequestContext {
  final String url;
  final String query;
  final Map<String, dynamic>? variables;
  final String? operationName;
  final Map<String, String>? headers;
  final int? timeoutMs;

  GraphQLRequestContext({
    required this.url,
    required this.query,
    this.variables,
    this.operationName,
    this.headers,
    this.timeoutMs,
  });
}

class GraphQLResponseData {
  final String url;
  final int status;
  final String statusText;
  final Map<String, String> headers;
  final String body;
  final dynamic data;
  final List<dynamic>? errors;
  final int duration;

  GraphQLResponseData({
    required this.url,
    required this.status,
    required this.statusText,
    required this.headers,
    required this.body,
    this.data,
    this.errors,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'status': status,
    'statusText': statusText,
    'headers': headers,
    'body': body,
    'data': data,
    'errors': errors,
    'duration': duration,
  };
}

class GraphQLResult {
  final bool success;
  final GraphQLResponseData data;
  final String? errorMsg;

  GraphQLResult({
    required this.success,
    required this.data,
    this.errorMsg,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': data.toJson(),
    if (errorMsg != null) 'errorMsg': errorMsg,
  };
}

Future<GraphQLResult> executeGraphQLRequest(GraphQLRequestContext ctx) async {
  final startTime = DateTime.now().millisecondsSinceEpoch;

  final payload = <String, dynamic>{
    'query': ctx.query,
  };
  if (ctx.variables != null && ctx.variables!.isNotEmpty) {
    payload['variables'] = ctx.variables;
  }
  if (ctx.operationName != null) {
    payload['operationName'] = ctx.operationName;
  }

  final mergedHeaders = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...?ctx.headers,
  };

  try {
    final request = http.Request('POST', Uri.parse(ctx.url));
    request.headers.addAll(mergedHeaders);
    request.body = jsonEncode(payload);

    final timeout = Duration(milliseconds: ctx.timeoutMs ?? 30000);
    final streamedResponse = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamedResponse);
    final duration = DateTime.now().millisecondsSinceEpoch - startTime;

    final status = response.statusCode;
    final statusText = response.reasonPhrase ?? "";
    
    dynamic parsedGql;
    String raw;
    try {
      parsedGql = jsonDecode(response.body);
      raw = JsonEncoder.withIndent('  ').convert(parsedGql);
    } catch (_) {
      raw = response.body;
      parsedGql = null;
    }

    dynamic responseData;
    List<dynamic>? errors;
    if (parsedGql is Map) {
      responseData = parsedGql['data'];
      if (parsedGql['errors'] is List) {
        errors = parsedGql['errors'];
      }
    }

    return GraphQLResult(
      success: true,
      data: GraphQLResponseData(
        url: ctx.url,
        status: status,
        statusText: statusText,
        headers: response.headers,
        body: raw,
        data: responseData,
        errors: errors,
        duration: duration,
      ),
    );
  } catch (err) {
    final duration = DateTime.now().millisecondsSinceEpoch - startTime;
    final msg = err.toString();
    return GraphQLResult(
      success: false,
      errorMsg: msg,
      data: GraphQLResponseData(
        url: ctx.url,
        status: 0,
        statusText: 'Network Error',
        headers: {},
        body: '',
        duration: duration,
      ),
    );
  }
}
