import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';

void registerAiLlmRequest(McpServer server) {
  server.registerTool(
    'ai-llm-request',
    description: 'Send a request to an AI LLM provider (OpenAI, Gemini, Groq, etc.)',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': {
        'provider': {'type': 'string', 'enum': ['openai', 'groq', 'mistral', 'gemini', 'anthropic']},
        'model': {'type': 'string'},
        'prompt': {'type': 'string'},
        'messages': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'role': {'type': 'string'},
              'content': {'type': 'string'}
            }
          }
        },
        'systemPrompt': {'type': 'string'},
        'apiKey': {'type': 'string'},
        'url': {'type': 'string'},
        'temperature': {'type': 'number'},
        'maxTokens': {'type': 'number'}
      }
    }),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      var messagesData = args['messages'] as List?;
      if (messagesData == null && args['prompt'] != null) {
        messagesData = [{'role': 'user', 'content': args['prompt']}];
      }
      messagesData ??= [];
      
      final ctx = AIRequestContext(
        url: args['url'] as String? ?? aiProviders[args['provider']]?['url'] as String? ?? 'https://api.openai.com/v1/chat/completions',
        apiKey: args['apiKey'] as String?,
        model: args['model'] as String? ?? 'gpt-3.5-turbo',
        messages: messagesData.map((m) => AIMessage(role: m['role'] as String, content: m['content'] as String)).toList(),
        systemPrompt: args['systemPrompt'] as String?,
        temperature: (args['temperature'] as num?)?.toDouble(),
        maxTokens: (args['maxTokens'] as num?)?.toInt(),
      );
      final result = await executeAIRequest(ctx);
      return CallToolResult.fromContent([TextContent(text: jsonEncode(result.toJson()))]);
    },
  );
}
