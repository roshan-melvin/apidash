import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

final wellKnownRouter = Router()
  ..get('/.well-known/mcp', (Request req) {
    return Response.ok(jsonEncode({
      'server_name': 'apidash-mcp',
      'version': '1.0.0',
    }), headers: {'Content-Type': 'application/json'});
  })
  ..get('/.well-known/oauth-protected-resource', (Request req) {
    final port = Platform.environment['PORT'] ?? '8000';
    return Response.ok(jsonEncode({
      "resource": "http://localhost:$port/mcp",
      "authorization_servers": ["http://localhost:$port"],
      "bearer_methods_supported": ["header"],
      "scopes_supported": ["mcp"]
    }), headers: {'Content-Type': 'application/json'});
  });
