import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:math';

// Generate a random string like base64url without padding
String _generateRandomString(int length) {
  final rand = Random.secure();
  final values = List<int>.generate(length, (i) => rand.nextInt(256));
  return base64UrlEncode(values).replaceAll('=', '');
}

final _clientsFile = File('${Platform.environment['HOME']}/.local/share/apidash/.oauth-clients.json');

class OAuthClient {
  final String clientId;
  final String? clientSecret;
  final List<String> redirectUris;
  final String? clientName;
  final List<String> grantTypes;
  final List<String> responseTypes;
  final String tokenEndpointAuthMethod;
  final String scope;
  final int createdAt;

  OAuthClient({
    required this.clientId,
    this.clientSecret,
    required this.redirectUris,
    this.clientName,
    required this.grantTypes,
    required this.responseTypes,
    required this.tokenEndpointAuthMethod,
    required this.scope,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'client_id': clientId,
    'client_secret': clientSecret,
    'redirect_uris': redirectUris,
    'client_name': clientName,
    'grant_types': grantTypes,
    'response_types': responseTypes,
    'token_endpoint_auth_method': tokenEndpointAuthMethod,
    'scope': scope,
    'created_at': createdAt,
  };

  factory OAuthClient.fromJson(Map<String, dynamic> json) => OAuthClient(
    clientId: json['client_id'] as String,
    clientSecret: json['client_secret'] as String?,
    redirectUris: (json['redirect_uris'] as List).cast<String>(),
    clientName: json['client_name'] as String?,
    grantTypes: (json['grant_types'] as List).cast<String>(),
    responseTypes: (json['response_types'] as List).cast<String>(),
    tokenEndpointAuthMethod: json['token_endpoint_auth_method'] as String,
    scope: json['scope'] as String? ?? 'mcp',
    createdAt: json['created_at'] as int,
  );
}

class AuthCode {
  final String code;
  final String clientId;
  final String redirectUri;
  final String codeChallenge;
  final String codeChallengeMethod;
  final String scope;
  final int expiresAt;

  AuthCode({
    required this.code,
    required this.clientId,
    required this.redirectUri,
    required this.codeChallenge,
    required this.codeChallengeMethod,
    required this.scope,
    required this.expiresAt,
  });
}

class AccessToken {
  final String token;
  final String clientId;
  final String scope;
  final int expiresAt;
  final String? refreshToken;

  AccessToken({
    required this.token,
    required this.clientId,
    required this.scope,
    required this.expiresAt,
    this.refreshToken,
  });
}

class RefreshToken {
  final String token;
  final String clientId;
  final String scope;

  RefreshToken({
    required this.token,
    required this.clientId,
    required this.scope,
  });
}

Map<String, OAuthClient> _loadClientsFromDisk() {
  try {
    if (_clientsFile.existsSync()) {
      final raw = _clientsFile.readAsStringSync();
      final arr = jsonDecode(raw) as List;
      final map = <String, OAuthClient>{};
      for (final item in arr) {
        final c = OAuthClient.fromJson(item as Map<String, dynamic>);
        map[c.clientId] = c;
      }
      return map;
    }
  } catch (e) {
    print('[oauth] Failed to load clients from disk: $e');
  }
  return {};
}

void _saveClientsToDisk(Map<String, OAuthClient> map) {
  try {
    _clientsFile.writeAsStringSync(jsonEncode(map.values.map((c) => c.toJson()).toList()),
        mode: FileMode.writeOnly);
  } catch (e) {
    print('[oauth] Failed to persist clients to disk: $e');
  }
}

final _clients = _loadClientsFromDisk();
final _authCodes = <String, AuthCode>{};
final _accessTokens = <String, AccessToken>{};
final _refreshTokens = <String, RefreshToken>{};

OAuthClient registerClient(Map<String, dynamic> data) {
  final clientId = _generateRandomString(16);
  final isPublic = data['token_endpoint_auth_method'] == 'none';
  final clientSecret = isPublic ? null : _generateRandomString(32);

  final client = OAuthClient(
    clientId: clientId,
    clientSecret: clientSecret,
    redirectUris: (data['redirect_uris'] as List?)?.cast<String>() ?? [],
    clientName: data['client_name'] as String?,
    grantTypes: (data['grant_types'] as List?)?.cast<String>() ?? ['authorization_code', 'refresh_token'],
    responseTypes: (data['response_types'] as List?)?.cast<String>() ?? ['code'],
    tokenEndpointAuthMethod: (data['token_endpoint_auth_method'] as String?) ?? 'none',
    scope: data['scope'] as String? ?? 'mcp',
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );

  _clients[clientId] = client;
  _saveClientsToDisk(_clients);
  print('[oauth] Registered client: $clientId (${client.clientName ?? "unnamed"}) — saved to disk');
  return client;
}

OAuthClient? getClient(String clientId) {
  return _clients[clientId];
}

AuthCode createAuthCode({
  required String clientId,
  required String redirectUri,
  required String codeChallenge,
  required String codeChallengeMethod,
  required String scope,
}) {
  final code = _generateRandomString(32);
  final ac = AuthCode(
    code: code,
    clientId: clientId,
    redirectUri: redirectUri,
    codeChallenge: codeChallenge,
    codeChallengeMethod: codeChallengeMethod,
    scope: scope,
    expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
  );
  _authCodes[code] = ac;
  return ac;
}

AuthCode? consumeAuthCode(String code) {
  final ac = _authCodes[code];
  if (ac == null) return null;
  _authCodes.remove(code);
  if (DateTime.now().millisecondsSinceEpoch > ac.expiresAt) return null;
  return ac;
}

AccessToken createAccessToken({
  required String clientId,
  required String scope,
}) {
  final token = _generateRandomString(32);
  final refreshToken = _generateRandomString(32);

  final at = AccessToken(
    token: token,
    clientId: clientId,
    scope: scope,
    expiresAt: DateTime.now().millisecondsSinceEpoch + 3600000, // 1 hr
    refreshToken: refreshToken,
  );

  _accessTokens[token] = at;
  _refreshTokens[refreshToken] = RefreshToken(
    token: refreshToken,
    clientId: clientId,
    scope: scope,
  );

  return at;
}

AccessToken? validateAccessToken(String token) {
  final at = _accessTokens[token];
  if (at == null) return null;
  if (DateTime.now().millisecondsSinceEpoch > at.expiresAt) {
    _accessTokens.remove(token);
    return null;
  }
  return at;
}

RefreshToken? consumeRefreshToken(String token) {
  final rt = _refreshTokens[token];
  if (rt == null) return null;
  _refreshTokens.remove(token);
  return rt;
}

bool revokeToken(String token) {
  if (_accessTokens.remove(token) != null) return true;
  if (_refreshTokens.remove(token) != null) return true;
  return false;
}
