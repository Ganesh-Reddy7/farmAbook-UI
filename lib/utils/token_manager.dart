import 'dart:convert';
import 'dart:developer'; // Added for logging errors
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  // Use constants for keys to prevent typos
  static const _authTokenKey = "auth_token";
  static const _tokenExpiryKey = "token_expiry";
  static const _userDataKey = "user_data";

  /// Saves the JWT token and its expiration timestamp.
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final payload = _decodePayload(token);
      final dynamic expiry = payload["exp"]; // JWT expiry timestamp (seconds)

      // 💡 Improvement: Validate expiry is an integer
      if (expiry is! int) {
        log('Error: "exp" field is missing or not an integer. Clearing token.');
        await clear();
        return;
      }

      await prefs.setString(_authTokenKey, token);
      await prefs.setInt(_tokenExpiryKey, expiry);

    } catch (e) {
      log('Error saving token: $e. Clearing partial data.');
      // Clear any partial data in case decoding failed
      await clear();
    }
  }

  /// Manually decodes the payload part of a JWT.
  static Map<String, dynamic> _decodePayload(String token) {
    final parts = token.split('.');

    // 💡 Improvement: Check for correct JWT structure (3 parts)
    if (parts.length != 3) {
      throw const FormatException('Invalid JWT structure: must have 3 parts.');
    }

    // Normalize padding for base64url decoding
    final payloadBase64 = parts[1];

    // The following try-catch handles both Base64 decoding errors and JSON parsing errors
    try {
      final payloadBytes = base64Url.decode(base64Url.normalize(payloadBase64));
      final payload = utf8.decode(payloadBytes);
      return jsonDecode(payload);
    } catch (e) {
      throw FormatException('Failed to decode JWT payload: $e');
    }
  }
  /// Retrieves the token, checks for expiration, and returns it if valid.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final expiry = prefs.getInt(_tokenExpiryKey);
    final token = prefs.getString(_authTokenKey);

    if (token == null || expiry == null) {
      return null;
    }

    // Current time in seconds (matching JWT exp format)
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    const bufferSeconds = 60;

    if (now >= expiry - bufferSeconds) {
      log('Token expired or is about to expire (within $bufferSeconds seconds). Auto-clearing...');
      await clear();
      return null;
    }

    return token;
  }

  /// Clears all authentication and user data from storage.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove(_userDataKey);
    log('All authentication data cleared.');
  }

  /// Saves user data (should be a JSON-serializable map).
  static Future<void> saveUser(dynamic user) async {
    final prefs = await SharedPreferences.getInstance();
    // Assuming 'user' is already a Map<String, dynamic> or similar.
    await prefs.setString(_userDataKey, jsonEncode(user));
  }

  /// Checks if a valid, non-expired token exists.
  static Future<bool> isLoggedIn() async {
    return (await getToken()) != null;
  }
}