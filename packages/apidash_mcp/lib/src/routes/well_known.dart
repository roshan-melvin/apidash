import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

final wellKnownRouter = Router()
  ..get('/.well-known/mcp', (Request req) {
    return Response.ok(jsonEncode({
      'server_name': 'apidash-mcp',
      'version': '1.0.0',
    }), headers: {'Content-Type': 'application/json'});
  });
