import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/user.dart';

class AuthService {
  // Replace with your laptop IP and backend port
  final String? baseUrl = dotenv.env['API_BASE_URL'];

  /// LOGIN
  Future<bool> login(String phone, String password) async {
    log("Attempting login with phone: $phone");
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone, "password": password}),
      );

      log("Login status: ${response.statusCode}");
      log("Login response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        final token = data['token'];

        // Save token & user locally
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", token);
        await prefs.setString("user_data", jsonEncode(user.toJson()));
        return true;
      } else {
        log("Login failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      log("Login exception: $e");
      return false;
    }
  }

  /// REGISTER
  Future<bool> register(String username, String phone, String password) async {
    log("Attempting register for username: $username");
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "phone": phone,
          "password": password,
        }),
      );

      log("Register status: ${response.statusCode}");
      log("Register response body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      log("Register exception: $e");
      return false;
    }
  }

  /// GET TOKEN
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  /// LOGOUT
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
  }
}
