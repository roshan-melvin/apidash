import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:crypto/crypto.dart';

import 'store.dart';

String baseUrl() {
  final port = Platform.environment['PORT'] ?? '8000';
  return Platform.environment['BASE_URL'] ?? 'http://localhost:$port';
}

final oauthRouter = Router()
  ..get('/.well-known/oauth-authorization-server', (Request req) {
    final base = baseUrl();
    return Response.ok(
      jsonEncode({
        'issuer': base,
        'authorization_endpoint': '$base/authorize',
        'token_endpoint': '$base/token',
        'registration_endpoint': '$base/register',
        'revocation_endpoint': '$base/token/revoke',
        'response_types_supported': ['code'],
        'grant_types_supported': ['authorization_code', 'refresh_token'],
        'token_endpoint_auth_methods_supported': ['none', 'client_secret_basic'],
        'code_challenge_methods_supported': ['S256'],
        'scopes_supported': ['mcp'],
        'resource_indicators_supported': true,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  })
  ..post('/register', (Request req) async {
    final payload = await req.readAsString();
    final body = jsonDecode(payload) as Map<String, dynamic>;

    final redirectUris = body['redirect_uris'];
    if (redirectUris == null || redirectUris is! List || redirectUris.isEmpty) {
      return Response(400,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'error': 'invalid_client_metadata',
            'error_description': 'redirect_uris is required and must be a non-empty array',
          }));
    }

    final client = registerClient(body);

    return Response(201,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id': client.clientId,
          'client_secret': client.clientSecret,
          'redirect_uris': client.redirectUris,
          'client_name': client.clientName,
          'grant_types': client.grantTypes,
          'response_types': client.responseTypes,
          'token_endpoint_auth_method': client.tokenEndpointAuthMethod,
          'scope': client.scope,
          'client_id_issued_at': client.createdAt ~/ 1000,
        }));
  })
  ..get('/authorize', (Request req) {
    final query = req.url.queryParameters;
    final responseType = query['response_type'];
    final clientId = query['client_id'];
    final redirectUri = query['redirect_uri'];
    final codeChallenge = query['code_challenge'];
    final codeChallengeMethod = query['code_challenge_method'];
    final scope = query['scope'] ?? 'mcp';
    final state = query['state'];

    if (responseType != 'code') {
      return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'error': 'unsupported_response_type'}));
    }
    if (clientId == null || redirectUri == null || codeChallenge == null) {
      return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
        'error': 'invalid_request',
        'error_description': 'client_id, redirect_uri, and code_challenge are required',
      }));
    }

    if (codeChallengeMethod != 'S256') {
      final url = Uri.parse(redirectUri);
      final newQuery = Map<String, String>.from(url.queryParameters)
        ..['error'] = 'invalid_request'
        ..['error_description'] = 'Only S256 code_challenge_method is supported (OAuth 2.1)';
      if (state != null) newQuery['state'] = state;
      final redirectUrl = url.replace(queryParameters: newQuery);
      return Response.found(redirectUrl.toString());
    }

    final client = getClient(clientId);
    if (client == null) {
      return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'error': 'invalid_client'}));
    }

    if (!client.redirectUris.contains(redirectUri)) {
      final requestedUrl = Uri.parse(redirectUri);
      bool isValidLocal = false;
      for (final uri in client.redirectUris) {
        final registeredUrl = Uri.parse(uri);
        if (requestedUrl.host == '127.0.0.1' &&
            registeredUrl.host == '127.0.0.1' &&
            requestedUrl.path.startsWith(registeredUrl.path)) {
          isValidLocal = true;
          break;
        }
      }
      if (!isValidLocal) {
        return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
          'error': 'invalid_request',
          'error_description': 'redirect_uri not registered for this client',
        }));
      }
    }

    final authCode = createAuthCode(
      clientId: clientId,
      redirectUri: redirectUri,
      codeChallenge: codeChallenge,
      codeChallengeMethod: 'S256',
      scope: scope,
    );

    final redirectUrlParsed = Uri.parse(redirectUri);
    final finalQuery = Map<String, String>.from(redirectUrlParsed.queryParameters)
      ..['code'] = authCode.code;
    if (state != null) finalQuery['state'] = state;
    final finalUrl = redirectUrlParsed.replace(queryParameters: finalQuery);

    final html = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>APIDash MCP — Authorize</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #0f0f11;
      color: #e4e4e7;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
    }
    .card {
      background: #18181b;
      border: 1px solid #27272a;
      border-radius: 12px;
      padding: 2rem;
      max-width: 400px;
      width: 90%;
      text-align: center;
    }
    .logo { font-size: 2.5rem; margin-bottom: 1rem; }
    h1 { font-size: 1.25rem; margin-bottom: 0.5rem; color: #f4f4f5; }
    p  { font-size: 0.875rem; color: #71717a; margin-bottom: 1.5rem; }
    .client { background: #27272a; border-radius: 6px; padding: 0.5rem 1rem;
              font-size: 0.8rem; color: #a1a1aa; margin-bottom: 1.5rem; }
    .scope { display: inline-block; background: #1e3a5f; color: #60a5fa;
             border-radius: 999px; padding: 0.25rem 0.75rem; font-size: 0.75rem;
             margin-bottom: 1.5rem; }
    .btn {
      display: block; width: 100%;
      background: linear-gradient(135deg, #6366f1, #8b5cf6);
      color: #fff; border: none; border-radius: 8px;
      padding: 0.75rem; font-size: 1rem; cursor: pointer;
      font-weight: 600; transition: opacity 0.2s;
    }
    .btn:hover { opacity: 0.9; }
    .auto { font-size: 0.75rem; color: #52525b; margin-top: 1rem; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">🔐</div>
    <h1>Authorize APIDash MCP</h1>
    <p>The following client is requesting access:</p>
    <div class="client">${client.clientName ?? clientId}</div>
    <div class="scope">scope: $scope</div>
    <a href="$finalUrl" class="btn">✓ Allow Access</a>
    <p class="auto">You will be redirected back to the application.</p>
  </div>
</body>
</html>''';

    return Response.ok(html, headers: {'Content-Type': 'text/html'});
  })
  ..post('/authorize/confirm', (Request req) async {
    final payload = await req.readAsString();
    final parts = Uri.splitQueryString(payload);
    final redirectUri = parts['redirect_uri'];
    if (redirectUri == null) {
      return Response(400, body: 'Missing redirect_uri');
    }
    return Response.found(redirectUri);
  })
  ..post('/token', (Request req) async {
    final payload = await req.readAsString();
    Map<String, dynamic> body;
    try {
      body = jsonDecode(payload);
    } catch (_) {
      try {
        body = Uri.splitQueryString(payload);
      } catch (_) {
        body = {};
      }
    }

    final grantType = body['grant_type'];
    final code = body['code'];
    final redirectUri = body['redirect_uri'];
    final codeVerifier = body['code_verifier'];
    final clientId = body['client_id'];
    final refreshToken = body['refresh_token'];

    if (grantType == 'authorization_code') {
      if (code == null || redirectUri == null || codeVerifier == null || clientId == null) {
        return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
          'error': 'invalid_request',
          'error_description': 'code, redirect_uri, code_verifier, and client_id are required'
        }));
      }

      final ac = consumeAuthCode(code);
      if (ac == null) {
        return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
          'error': 'invalid_grant',
          'error_description': 'Authorization code is invalid or expired'
        }));
      }

      if (ac.clientId != clientId) {
        return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'error': 'invalid_grant', 'error_description': 'client_id mismatch'}));
      }
      if (ac.redirectUri != redirectUri) {
        return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'error': 'invalid_grant', 'error_description': 'redirect_uri mismatch'}));
      }

      final bytes = utf8.encode(codeVerifier);
      final hash = base64UrlEncode(sha256.convert(bytes).bytes).replaceAll('=', '');

      if (hash != ac.codeChallenge) {
        return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
          'error': 'invalid_grant',
          'error_description': 'PKCE code_verifier does not match code_challenge'
        }));
      }

      final at = createAccessToken(clientId: clientId, scope: ac.scope);
      return Response.ok(jsonEncode({
        'access_token': at.token,
        'token_type': 'Bearer',
        'expires_in': 3600,
        'refresh_token': at.refreshToken,
        'scope': at.scope,
      }), headers: {'Content-Type': 'application/json'});
    }

    if (grantType == 'refresh_token') {
      if (refreshToken == null || clientId == null) {
        return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
          'error': 'invalid_request',
          'error_description': 'refresh_token and client_id are required'
        }));
      }

      final rt = consumeRefreshToken(refreshToken);
      if (rt == null || rt.clientId != clientId) {
        return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
          'error': 'invalid_grant',
          'error_description': 'Refresh token is invalid, expired, or does not belong to this client'
        }));
      }

      final at = createAccessToken(clientId: rt.clientId, scope: rt.scope);
      return Response.ok(jsonEncode({
        'access_token': at.token,
        'token_type': 'Bearer',
        'expires_in': 3600,
        'refresh_token': at.refreshToken,
        'scope': at.scope,
      }), headers: {'Content-Type': 'application/json'});
    }

    return Response(400, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
      'error': 'unsupported_grant_type',
      'error_description': 'grant_type \'\$grantType\' is not supported',
    }));
  })
  ..post('/token/revoke', (Request req) async {
    final payload = await req.readAsString();
    Map<String, dynamic> body;
    try {
      body = jsonDecode(payload);
    } catch (_) {
      try {
        body = Uri.splitQueryString(payload);
      } catch (_) {
        body = {};
      }
    }
    final token = body['token'];
    if (token != null) revokeToken(token);
    return Response.ok('');
  });
