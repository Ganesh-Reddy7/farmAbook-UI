import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InvestmentService {
  // Base URL from your backend
  final String baseUrl = "http://10.94.67.202:8080/api";

  /// Save single investment
  Future<bool> saveInvestment({
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    try {
      final formattedDate = "${date.year.toString().padLeft(4,'0')}-"
          "${date.month.toString().padLeft(2,'0')}-"
          "${date.day.toString().padLeft(2,'0')}";

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final userData = prefs.getString("user_data");

      if (token == null || userData == null) {
        log("Token or user data missing");
        return false;
      }

      final user = jsonDecode(userData);
      final farmerId = user['id'];

      final body = jsonEncode({
        "farmerId": farmerId,
        "amount": amount,
        "description": description,
        "date": formattedDate,
      });

      final response = await http.post(
        Uri.parse("$baseUrl/investments"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      log("Save Investment status: ${response.statusCode}");
      log("Save Investment response: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      log("Save Investment exception: $e");
      return false;
    }
  }

  /// Save investment with workers
  Future<bool> saveInvestmentWithWorkers({
    required String description,
    required DateTime date,
    required List<Map<String, dynamic>> workers,
  }) async {
    try {
      final formattedDate = "${date.year.toString().padLeft(4,'0')}-"
          "${date.month.toString().padLeft(2,'0')}-"
          "${date.day.toString().padLeft(2,'0')}";
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final userData = prefs.getString("user_data");

      if (token == null || userData == null) {
        log("Token or user data missing");
        return false;
      }

      final user = jsonDecode(userData);
      final farmerId = user['id'];

      final body = jsonEncode({
        "farmerId": farmerId,
        "description": description,
        "date":formattedDate,
        "workers": workers, // each worker: {name, wage, role}
      });

      final response = await http.post(
        Uri.parse("$baseUrl/investments/create-with-workers"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      log("Save Investment with Workers status: ${response.statusCode}");
      log("Response: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      log("Save Investment with Workers exception: $e");
      return false;
    }
  }
}
