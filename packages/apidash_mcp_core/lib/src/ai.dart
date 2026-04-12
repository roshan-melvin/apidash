import 'dart:convert';
import 'package:http/http.dart' as http;

class AIMessage {
  final String role;
  final String content;

  AIMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };
}

class AIRequestContext {
  final String url;
  final String? apiKey;
  final String model;
  final List<AIMessage> messages;
  final String? systemPrompt;
  final double? temperature;
  final int? maxTokens;
  final bool? stream;
  final Map<String, String>? headers;
  final int? timeoutMs;

  AIRequestContext({
    required this.url,
    this.apiKey,
    required this.model,
    required this.messages,
    this.systemPrompt,
    this.temperature = 0.7,
    this.maxTokens = 1024,
    this.stream,
    this.headers,
    this.timeoutMs = 60000,
  });
}

class AIResponseData {
  final String url;
  final String model;
  final int status;
  final String statusText;
  final String content;
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;
  final String? finishReason;
  final int duration;
  final String rawBody;

  AIResponseData({
    required this.url,
    required this.model,
    required this.status,
    required this.statusText,
    required this.content,
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
    this.finishReason,
    required this.duration,
    required this.rawBody,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'model': model,
    'status': status,
    'statusText': statusText,
    'content': content,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'totalTokens': totalTokens,
    'finishReason': finishReason,
    'duration': duration,
    'rawBody': rawBody,
  };
}

class AIResult {
  final bool success;
  final AIResponseData data;
  final String? errorMsg;

  AIResult({
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

const aiProviders = {
  'openai': {'url': 'https://api.openai.com/v1/chat/completions', 'label': 'OpenAI'},
  'groq': {'url': 'https://api.groq.com/openai/v1/chat/completions', 'label': 'Groq'},
  'mistral': {'url': 'https://api.mistral.ai/v1/chat/completions', 'label': 'Mistral AI'},
  'together': {'url': 'https://api.together.xyz/v1/chat/completions', 'label': 'Together AI'},
  'ollama': {'url': 'http://localhost:11434/api/chat', 'label': 'Ollama (local)'},
  'gemini': {'url': 'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions', 'label': 'Google Gemini'},
  'anthropic': {'url': 'https://api.anthropic.com/v1/messages', 'label': 'Anthropic Claude'},
};

Future<AIResult> executeAIRequest(AIRequestContext ctx) async {
  final startTime = DateTime.now().millisecondsSinceEpoch;

  final fullMessages = <AIMessage>[];
  if (ctx.systemPrompt != null) {
    fullMessages.add(AIMessage(role: 'system', content: ctx.systemPrompt!));
  }
  fullMessages.addAll(ctx.messages);

  final mergedHeaders = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  if (ctx.apiKey != null && ctx.apiKey!.isNotEmpty) {
    mergedHeaders['Authorization'] = 'Bearer ${ctx.apiKey}';
  }
  if (ctx.headers != null) {
    mergedHeaders.addAll(ctx.headers!);
  }

  final payload = {
    'model': ctx.model,
    'messages': fullMessages.map((m) => m.toJson()).toList(),
    'temperature': ctx.temperature,
    'max_tokens': ctx.maxTokens,
  };

  try {
    final request = http.Request('POST', Uri.parse(ctx.url));
    request.headers.addAll(mergedHeaders);
    request.body = jsonEncode(payload);

    final timeout = Duration(milliseconds: ctx.timeoutMs ?? 60000);
    final streamedResponse = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamedResponse);
    final duration = DateTime.now().millisecondsSinceEpoch - startTime;

    final status = response.statusCode;
    final statusText = response.reasonPhrase ?? "";

    dynamic d;
    String raw;
    try {
      d = jsonDecode(response.body);
      raw = JsonEncoder.withIndent('  ').convert(d);
    } catch (_) {
      d = {};
      raw = response.body;
    }

    dynamic choice;
    if (d['choices'] is List && d['choices'].isNotEmpty) {
      choice = d['choices'][0];
    }
    
    String content = "";
    if (choice != null && choice['message'] != null && choice['message']['content'] != null) {
      content = choice['message']['content'].toString();
    } else if (d['content'] is List && d['content'].isNotEmpty && d['content'][0]['text'] != null) {
      content = d['content'][0]['text'].toString();
    } else if (d['message'] != null && d['message']['content'] != null) {
      content = d['message']['content'].toString();
    }

    final usage = d['usage'];
    int? inputTokens;
    int? outputTokens;
    int? totalTokens;
    if (usage != null) {
      inputTokens = usage['prompt_tokens'] ?? usage['input_tokens'];
      outputTokens = usage['completion_tokens'] ?? usage['output_tokens'];
      totalTokens = usage['total_tokens'];
    }

    String? finishReason;
    if (choice != null) {
      finishReason = choice['finish_reason']?.toString();
    }

    final bool success = status < 400;
    String? errorMsg;
    if (!success) {
      errorMsg = 'HTTP $status: ${raw.length > 200 ? raw.substring(0, 200) : raw}';
    }

    return AIResult(
      success: success,
      data: AIResponseData(
        url: ctx.url,
        model: ctx.model,
        status: status,
        statusText: statusText,
        content: content,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        totalTokens: totalTokens,
        finishReason: finishReason,
        duration: duration,
        rawBody: raw,
      ),
      errorMsg: errorMsg,
    );
  } catch (err) {
    final duration = DateTime.now().millisecondsSinceEpoch - startTime;
    final msg = err.toString();
    return AIResult(
      success: false,
      errorMsg: msg,
      data: AIResponseData(
        url: ctx.url,
        model: ctx.model,
        status: 0,
        statusText: "Network Error",
        content: "",
        duration: duration,
        rawBody: "",
      ),
    );
  }
}
