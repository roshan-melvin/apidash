import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../tool_ui_helper.dart';

/// Pre-built request templates shipped with APIDash MCP.
const _templates = <String, Map<String, dynamic>>{
  'get-posts': {
    'id': 'get-posts',
    'name': 'Get All Posts',
    'method': 'GET',
    'url': 'https://jsonplaceholder.typicode.com/posts',
    'description': 'Fetches all posts from the JSONPlaceholder API',
    'headers': <String, dynamic>{},
  },
  'get-post': {
    'id': 'get-post',
    'name': 'Get Single Post',
    'method': 'GET',
    'url': 'https://jsonplaceholder.typicode.com/posts/1',
    'description': 'Fetches post #1 from JSONPlaceholder',
    'headers': <String, dynamic>{},
  },
  'create-post': {
    'id': 'create-post',
    'name': 'Create Post',
    'method': 'POST',
    'url': 'https://jsonplaceholder.typicode.com/posts',
    'description': 'Creates a new post',
    'headers': {'Content-Type': 'application/json'},
    'body': '{"title": "foo", "body": "bar", "userId": 1}',
  },
  'update-post': {
    'id': 'update-post',
    'name': 'Update Post',
    'method': 'PUT',
    'url': 'https://jsonplaceholder.typicode.com/posts/1',
    'description': 'Updates post #1',
    'headers': {'Content-Type': 'application/json'},
    'body': '{"id": 1, "title": "updated title", "body": "updated body", "userId": 1}',
  },
  'delete-post': {
    'id': 'delete-post',
    'name': 'Delete Post',
    'method': 'DELETE',
    'url': 'https://jsonplaceholder.typicode.com/posts/1',
    'description': 'Deletes post #1',
    'headers': <String, dynamic>{},
  },
  'get-users': {
    'id': 'get-users',
    'name': 'Get Users',
    'method': 'GET',
    'url': 'https://jsonplaceholder.typicode.com/users',
    'description': 'Fetches all users',
    'headers': <String, dynamic>{},
  },
  'get-comments': {
    'id': 'get-comments',
    'name': 'Get Comments',
    'method': 'GET',
    'url': 'https://jsonplaceholder.typicode.com/comments?postId=1',
    'description': 'Fetches comments for post #1',
    'headers': <String, dynamic>{},
  },
  'github-user': {
    'id': 'github-user',
    'name': 'GitHub User',
    'method': 'GET',
    'url': 'https://api.github.com/users/octocat',
    'description': 'Fetches GitHub user profile for octocat',
    'headers': {'Accept': 'application/vnd.github.v3+json'},
  },
  'httpbin-get': {
    'id': 'httpbin-get',
    'name': 'HTTPBin GET',
    'method': 'GET',
    'url': 'https://httpbin.org/get',
    'description': 'Test GET request via HTTPBin',
    'headers': <String, dynamic>{},
  },
  'httpbin-post': {
    'id': 'httpbin-post',
    'name': 'HTTPBin POST',
    'method': 'POST',
    'url': 'https://httpbin.org/post',
    'description': 'Test POST request via HTTPBin',
    'headers': {'Content-Type': 'application/json'},
    'body': '{"name": "apidash", "version": "2.0"}',
  },
};

void registerGetApiRequestTemplate(McpServer server) {
  server.registerTool(
    'get-api-request-template',
    description: 'Load a pre-built API request template by ID and open it in the Request Builder panel. '
        'Available template IDs: ${_templates.keys.join(", ")}.',
    inputSchema: ToolInputSchema.fromJson(<String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'templateId': <String, dynamic>{
          'type': 'string',
          'enum': _templates.keys.toList(),
          'description': 'Template ID to load',
        },
        'method': <String, dynamic>{
          'type': 'string',
          'enum': ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD'],
          'description': 'Override method (optional)',
        },
      },
    }),
    meta: {
      'ui': {
        'resourceUri': kUriRequestBuilder,
        'visibility': ['model', 'app'],
      },
    },
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final templateId = args['templateId'] as String? ?? 'get-posts';
      final template = _templates[templateId] ?? _templates['get-posts']!;

      // Also check workspace for user-saved requests
      final userRequests = WorkspaceState().requests;
      final userMatch = userRequests.where((r) => r['id'] == templateId).firstOrNull;
      final resolved = userMatch ?? template;

      WorkspaceState().pendingBuilderPreload = Map<String, dynamic>.from(resolved);

      return CallToolResult(
        content: [
          TextContent(
            text: '✓ Loaded template **${resolved['name']}** — `${resolved['method']} ${resolved['url']}`\n\n'
                '```json\n${const JsonEncoder.withIndent('  ').convert(resolved)}\n```',
          ),
        ],
        structuredContent: resolved,
      );
    },
  );
}
