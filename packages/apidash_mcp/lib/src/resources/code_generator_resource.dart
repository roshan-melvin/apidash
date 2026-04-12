import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../ui/panels/code_generator_panel.dart';

/// Built-in request templates — always shown even when WorkspaceState is empty.
const builtinTemplates = <Map<String, dynamic>>[
  {'id': 'get-posts',    'name': 'Get All Posts',    'method': 'GET',    'url': 'https://jsonplaceholder.typicode.com/posts',    'description': 'Fetch all posts'},
  {'id': 'get-post',     'name': 'Get Single Post',  'method': 'GET',    'url': 'https://jsonplaceholder.typicode.com/posts/1',  'description': 'Fetch post #1'},
  {'id': 'create-post',  'name': 'Create Post',      'method': 'POST',   'url': 'https://jsonplaceholder.typicode.com/posts',    'description': 'Create a new post', 'body': '{"title":"foo","body":"bar","userId":1}'},
  {'id': 'update-post',  'name': 'Update Post',      'method': 'PUT',    'url': 'https://jsonplaceholder.typicode.com/posts/1',  'description': 'Update post #1'},
  {'id': 'delete-post',  'name': 'Delete Post',      'method': 'DELETE', 'url': 'https://jsonplaceholder.typicode.com/posts/1',  'description': 'Delete post #1'},
  {'id': 'get-users',    'name': 'Get Users',        'method': 'GET',    'url': 'https://jsonplaceholder.typicode.com/users',    'description': 'Fetch all users'},
  {'id': 'get-comments', 'name': 'Get Comments',     'method': 'GET',    'url': 'https://jsonplaceholder.typicode.com/comments?postId=1', 'description': 'Fetch comments for post #1'},
  {'id': 'github-user',  'name': 'GitHub User',      'method': 'GET',    'url': 'https://api.github.com/users/octocat',          'description': 'GitHub user profile'},
  {'id': 'httpbin-get',  'name': 'HTTPBin GET',      'method': 'GET',    'url': 'https://httpbin.org/get',                       'description': 'Test GET via HTTPBin'},
  {'id': 'httpbin-post', 'name': 'HTTPBin POST',     'method': 'POST',   'url': 'https://httpbin.org/post',                      'description': 'Test POST via HTTPBin', 'body': '{"name":"apidash"}'},
];

void registerCodeGeneratorResource(McpServer server) {
  server.registerResource(
    'code-generator-ui',
    'ui://apidash-mcp/code-generator',
    (description: 'Code Generator panel — generate HTTP request snippets in 12 languages.', mimeType: 'text/html;profile=mcp-app'),
    (Uri uri, RequestHandlerExtra extra) async {
      final wsRequests = WorkspaceState().requests;
      final wsIds = wsRequests.map((r) => r['id'] as String? ?? '').toSet();
      final allRequests = [
        ...wsRequests,
        ...builtinTemplates.where((t) => !wsIds.contains(t['id'] as String)),
      ];
      
      var html = buildCodeGeneratorPanel(supportedGenerators);

      // Inject the full request list
      final injectionScript = '<script>window.__INITIAL_CONTEXT__ = ${jsonEncode(allRequests)};</script>';
      html = html.replaceFirst('</head>', '$injectionScript\n</head>');

      // Inject preload ID if a specific request was requested via codegen-ui tool
      final preloadId = WorkspaceState().pendingCodegenPreloadId;
      if (preloadId != null) {
        final preloadScript = '<script>window.__PRELOAD_REQUEST_ID__ = ${jsonEncode(preloadId)};</script>';
        html = html.replaceFirst('</head>', '$preloadScript\n</head>');
        WorkspaceState().pendingCodegenPreloadId = null; // consume once
      }

      return ReadResourceResult(
        contents: [
          TextResourceContents(uri: uri.toString(), mimeType: 'text/html;profile=mcp-app', text: html),
        ],
      );
    },
    title: 'Code Generator',
  );
}
