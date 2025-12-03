import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';
import '../utils/app_toast.dart';

class ApiService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? "";

  // ---------------------------------------------------------------------------
  // 🔹 Load token + user
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

  Map<String, String> _headers(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  // ---------------------------------------------------------------------------
  // 🔥 UNIVERSAL API CALL HANDLER (applies to GET/POST/PUT/DELETE)
  // ---------------------------------------------------------------------------
  Future<ApiResponse?> _request(
      Future<http.Response> Function() call,
      BuildContext context,
      ) async {
    try {
      final res = await call();

      log("Response ${res.statusCode}: ${res.body}");

      final decoded = jsonDecode(res.body);
      final api = ApiResponse.fromJson(decoded);

      // 🔥 Token expired → Logout user
      if (api.statusCode == 401 ||
          api.message.toLowerCase().contains("token")) {
        await _handleTokenExpiry(context);
        return null;
      }

      // ❌ Failure → show popup
      if (!api.status) {
        AppToast.showError(context, api.message);
      }

      return api;
    } catch (e) {
      AppToast.showError(context, "Something went wrong!");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 GET
  // ---------------------------------------------------------------------------
  Future<ApiResponse?> get(String endpoint, BuildContext context) async {
    final auth = await _loadAuth();
    final url = Uri.parse("$baseUrl$endpoint");

    return _request(
          () => http.get(url, headers: _headers(auth["token"]!)),
      context,
    );
  }

  // ---------------------------------------------------------------------------
  // 🔹 POST
  // ---------------------------------------------------------------------------
  Future<ApiResponse?> post(
      String endpoint, Map<String, dynamic> body, BuildContext context) async {
    final auth = await _loadAuth();
    final url = Uri.parse("$baseUrl$endpoint");

    body["farmerId"] = auth["farmerId"];

    return _request(
          () => http.post(
        url,
        headers: _headers(auth["token"]!),
        body: jsonEncode(body),
      ),
      context,
    );
  }

  // ---------------------------------------------------------------------------
  // 🔹 PUT
  // ---------------------------------------------------------------------------
  Future<ApiResponse?> put(
      String endpoint, Map<String, dynamic> body, BuildContext context) async {
    final auth = await _loadAuth();
    final url = Uri.parse("$baseUrl$endpoint");

    return _request(
          () => http.put(
        url,
        headers: _headers(auth["token"]!),
        body: jsonEncode(body),
      ),
      context,
    );
  }

  // ---------------------------------------------------------------------------
  // 🔹 DELETE
  // ---------------------------------------------------------------------------
  Future<ApiResponse?> delete(String endpoint, BuildContext context) async {
    final auth = await _loadAuth();
    final url = Uri.parse("$baseUrl$endpoint");

    return _request(
          () => http.delete(url, headers: _headers(auth["token"]!)),
      context,
    );
  }

  // ---------------------------------------------------------------------------
  // 🔥 GLOBAL TOKEN EXPIRY HANDLER
  // ---------------------------------------------------------------------------
  Future<void> _handleTokenExpiry(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    AppToast.showError(context, "Session expired. Please login again.");

    Navigator.pushNamedAndRemoveUntil(context, "/auth", (route) => false);
  }
}
