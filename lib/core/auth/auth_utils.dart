import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized authentication helpers to avoid duplicated code across screens.
class AuthUtils {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Returns true if an access token exists and is non-empty.
  /// Supports both raw string tokens and JSON encoded: { "access_token": "..." }.
  static Future<bool> isLoggedIn() async {
    try {
      final tokenRaw = await _storage.read(key: 'access_token');
      if (tokenRaw == null || tokenRaw.isEmpty) return false;
      try {
        final parsed = jsonDecode(tokenRaw);
        if (parsed is Map && parsed['access_token'] is String) {
          return (parsed['access_token'] as String).isNotEmpty;
        }
      } catch (_) {}
      return tokenRaw.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns the bearer token string if available, otherwise null.
  /// Handles both raw string and JSON formats.
  static Future<String?> getAccessToken() async {
    try {
      final tokenRaw = await _storage.read(key: 'access_token');
      if (tokenRaw == null || tokenRaw.isEmpty) return null;
      try {
        final parsed = jsonDecode(tokenRaw);
        if (parsed is Map && parsed['access_token'] is String) {
          final t = (parsed['access_token'] as String).trim();
          return t.isEmpty ? null : t;
        }
      } catch (_) {}
      final t = tokenRaw.trim();
      return t.isEmpty ? null : t;
    } catch (_) {
      return null;
    }
  }
}
