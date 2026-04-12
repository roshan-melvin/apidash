import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import '../oauth/store.dart';

Middleware bearerAuth() {
  return (Handler innerHandler) {
    return (Request request) async {
      final oauthMode = Platform.environment['APIDASH_MCP_AUTH'] == 'true';
      final staticSecret = Platform.environment['APIDASH_MCP_TOKEN'];

      if (!oauthMode && (staticSecret == null || staticSecret.isEmpty)) {
        return innerHandler(request);
      }

      final authHeader = request.headers['authorization'] ?? '';

      final baseUrl = Platform.environment['BASE_URL'] ?? 'http://localhost:${Platform.environment['PORT'] ?? '3001'}';

      if (!authHeader.startsWith('Bearer ')) {
        return Response(401,
          headers: {
            'WWW-Authenticate': 'Bearer realm="apidash-mcp", error="invalid_token", error_description="Bearer token required. Obtain one from POST /token", resource_metadata="$baseUrl/.well-known/oauth-protected-resource"',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'error': 'invalid_token',
            'error_description': 'Authorization: Bearer <token> header is required',
            'token_endpoint': '$baseUrl/token',
          }),
        );
      }

      final rawToken = authHeader.substring(7).trim();

      if (validateAccessToken(rawToken) != null) {
        return innerHandler(request);
      }

      if (staticSecret != null && rawToken == staticSecret) {
        return innerHandler(request);
      }

      return Response(401,
        headers: {
          'WWW-Authenticate': 'Bearer realm="apidash-mcp", error="invalid_token", error_description="Token is invalid or expired", resource_metadata="$baseUrl/.well-known/oauth-protected-resource"',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'error': 'invalid_token',
          'error_description': oauthMode
              ? 'Token is invalid or expired. Use the OAuth 2.1 flow to get a new token.'
              : 'Token is invalid or expired.',
          'token_endpoint': '$baseUrl/token',
        }),
      );
    };
  };
}
