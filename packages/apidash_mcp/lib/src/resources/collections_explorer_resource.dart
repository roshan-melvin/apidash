import 'dart:convert';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';
import '../ui/panels/collections_explorer_panel.dart';

/// Built-in request templates — always shown even when WorkspaceState is empty.
const _builtinTemplates = <Map<String, dynamic>>[
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

void registerCollectionsExplorerResource(McpServer server) {
  server.registerResource(
    'collections-explorer-ui',
    'ui://apidash-mcp/collections-explorer',
    (description: 'Browse all saved API requests from the APIDash workspace and built-in templates.', mimeType: 'text/html;profile=mcp-app'),
    (Uri uri, RequestHandlerExtra extra) async {
      // Merge workspace requests (from Flutter sync) with built-in templates.
      // Workspace requests take precedence — deduplicated by id.
      final wsRequests = WorkspaceState().requests;
      final wsIds = wsRequests.map((r) => r['id'] as String? ?? '').toSet();
      final allRequests = [
        ...wsRequests,
        ..._builtinTemplates.where((t) => !wsIds.contains(t['id'] as String)),
      ];

      final jsonData = const JsonEncoder().convert(allRequests);
      var html = buildCollectionsExplorerPanel();

      // Inject data into <head> so it's guaranteed available before the panel script runs
      final injectionScript = '<script>window.__INITIAL_DATA__ = $jsonData;</script>';
      html = html.replaceFirst('</head>', '$injectionScript\n</head>');

      return ReadResourceResult(
        contents: [
          TextResourceContents(uri: uri.toString(), mimeType: 'text/html;profile=mcp-app', text: html),
        ],
      );
    },
    title: 'Collections Explorer',
  );
}
