import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashGate {
  static final Map<String, String> _toolHashRegistry = {};

  static void registerToolSignature(String toolName, String schemaJson) {
    final bytes = utf8.encode(toolName + schemaJson);
    final digest = sha256.convert(bytes);
    _toolHashRegistry[toolName] = digest.toString();
  }

  static bool validate(String toolName, String schemaJson) {
    if (!_toolHashRegistry.containsKey(toolName)) {
      return false;
    }
    
    final bytes = utf8.encode(toolName + schemaJson);
    final digest = sha256.convert(bytes).toString();
    return _toolHashRegistry[toolName] == digest;
  }
}
