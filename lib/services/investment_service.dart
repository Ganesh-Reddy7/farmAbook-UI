import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/yearly_summary.dart';
import '../models/investment.dart';

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

  /// Get investments for a specific financial year
  Future<List<Investment>> getInvestmentsByFinancialYear({
    required int year,
    required bool includeWorkers,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final userData = prefs.getString("user_data");

      if (token == null || userData == null) {
        log("Token or user data missing");
        return [];
      }

      final user = jsonDecode(userData);
      final farmerId = user['id'];

      final url = Uri.parse(
        "$baseUrl/investments/financial-year/$year/flex"
            "?includeWorkers=$includeWorkers&farmerId=$farmerId",
      );

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      log("Get Investments By Financial Year status: ${response.statusCode}");
      log("Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => Investment.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      log("Get Investments By Financial Year exception: $e");
      return [];
    }
  }

  /// Get yearly summary for farmer between range
  Future<List<YearlyInvestmentSummaryDTO>> getYearlySummaryForFarmer({required int startYear, required int endYear}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final userData = prefs.getString("user_data");
    if (token == null || userData == null) return [];

    final user = jsonDecode(userData);
    final farmerId = user['id'];

    final uri = Uri.parse(
        "$baseUrl/investments/financial-year/range/summary/$farmerId?startYear=$startYear&endYear=$endYear"
    );

    final response = await http.get(uri, headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json"
    });
    log("Response: ${response.body}");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      log("GKaaxx :: data :: , $data");
      return data.map((e) => YearlyInvestmentSummaryDTO.fromJson(e)).toList();
    }
    return [];
  }


}
