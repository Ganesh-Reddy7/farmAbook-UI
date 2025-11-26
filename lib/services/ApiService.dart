import 'dart:convert';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? "";

  // ---------------------------------------------------------------------------
  // 🔹 Load token + user (common for all APIs)
  // ---------------------------------------------------------------------------
  Future<Map<String, String>> _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final userData = prefs.getString("user_data");

    if (token == null || userData == null) {
      throw Exception("User not authenticated. Please login again.");
    }

    final farmerId = jsonDecode(userData)['id'].toString();

    return {"token": token, "farmerId": farmerId};
  }

  // ---------------------------------------------------------------------------
  // 🔹 Common Headers
  // ---------------------------------------------------------------------------
  Map<String, String> _headers(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  // ---------------------------------------------------------------------------
  // 🔹 GET API
  // ---------------------------------------------------------------------------
  Future<dynamic> get(String endpoint) async {
    final auth = await _loadAuth();
    final url = Uri.parse("$baseUrl$endpoint");

    log("GET → $url");

    try {
      final res = await http.get(url, headers: _headers(auth["token"]!));

      log("GET Response (${res.statusCode}) → ${res.body}");

      return _handleResponse(res);
    } catch (e) {
      throw Exception("GET request failed: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 POST API
  // ---------------------------------------------------------------------------
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final auth = await _loadAuth();
    final url = Uri.parse("$baseUrl$endpoint");

    body["farmerId"] = auth["farmerId"];

    log("POST → $url");
    log("Body → $body");

    try {
      final res = await http.post(
        url,
        headers: _headers(auth["token"]!),
        body: jsonEncode(body),
      );

      log("POST Response (${res.statusCode}) → ${res.body}");

      return _handleResponse(res);
    } catch (e) {
      throw Exception("POST request failed: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 PUT API
  // ---------------------------------------------------------------------------
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final auth = await _loadAuth();
    final url = Uri.parse("$baseUrl$endpoint");

    log("PUT → $url");
    log("Body → $body");

    try {
      final res = await http.put(
        url,
        headers: _headers(auth["token"]!),
        body: jsonEncode(body),
      );

      log("PUT Response (${res.statusCode}) → ${res.body}");

      return _handleResponse(res);
    } catch (e) {
      throw Exception("PUT request failed: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 DELETE API
  // ---------------------------------------------------------------------------
  Future<dynamic> delete(String endpoint) async {
    final auth = await _loadAuth();
    final url = Uri.parse("$baseUrl$endpoint");

    log("DELETE → $url");

    try {
      final res = await http.delete(url, headers: _headers(auth["token"]!));

      log("DELETE Response (${res.statusCode}) → ${res.body}");

      return _handleResponse(res);
    } catch (e) {
      throw Exception("DELETE request failed: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 Response Handler (shared for all APIs)
  // ---------------------------------------------------------------------------
  dynamic _handleResponse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;

      try {
        return jsonDecode(res.body);
      } catch (e) {
        return res.body;
      }
    } else {
      throw Exception("API failed: ${res.statusCode} → ${res.body}");
    }
  }
}
