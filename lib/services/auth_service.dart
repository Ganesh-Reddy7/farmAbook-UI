import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer';

import '../models/user.dart';
import '../utils/api_exception.dart';
import '../utils/token_manager.dart';

class AuthService {
  final String? baseUrl = dotenv.env['API_BASE_URL'];

  /// ---------------- LOGIN ----------------
  Future<User> login(String phone, String password) async {
    final url = Uri.parse("$baseUrl/users/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone, "password": password}),
      );

      return _handleLoginResponse(response);

    } catch (e) {
      throw ApiException("Unable to connect to server");
    }
  }

  User _handleLoginResponse(http.Response response) {
    log("Login Status: ${response.statusCode}");
    log("Login Body: ${response.body}");

    final body = jsonDecode(response.body);

    final bool result = body["result"] ?? false;
    final String message = body["message"] ?? "Unknown error";

    if (!result) {
      throw ApiException(message);
    }

    final data = body["response"];
    if (data == null) {
      throw ApiException("Invalid server response");
    }

    final token = data["token"];
    final user = User.fromJson(data["user"]);

    // IMPORTANT: Save token & expiry here
    TokenManager.saveToken(token);
    TokenManager.saveUser(user.toJson());

    return user;
  }

  /// ---------------- REGISTER ----------------
  Future<bool> register(String username, String phone, String password) async {
    final url = Uri.parse("$baseUrl/users/register");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "phone": phone,
          "password": password,
        }),
      );

      return _handleRegisterResponse(response);

    } catch (e) {
      throw ApiException("Unable to connect to server");
    }
  }

  bool _handleRegisterResponse(http.Response response) {
    final body = jsonDecode(response.body);

    final result = body["result"] ?? false;
    final String? message = body["message"];

    if (!result) {
      throw ApiException(message ?? "Registration failed");
    }

    return true;
  }

  /// ---------------- GET TOKEN ----------------
  Future<String?> getToken() async => TokenManager.getToken();

  /// ---------------- LOGOUT ----------------
  Future<void> logout() async => TokenManager.clear();
}
