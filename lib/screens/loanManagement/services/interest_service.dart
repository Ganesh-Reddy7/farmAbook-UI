import 'dart:convert';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/interest_history.dart';
import '../models/interest_response.dart';

class InterestService {
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

  String get baseUrl => dotenv.env['API_BASE_URL']!;
  Future<InterestResult> calculateSimpleInterest({
    required double principal,
    required double rate,
    required int timeInMonths,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final auth = await _loadAuth();
    final int farmerId = int.parse(auth["farmerId"]!);
    final String token = auth["token"]!;
    final response = await http.post(
      Uri.parse("$baseUrl/interest/simple"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",

      },
      body: jsonEncode({
        "principal": principal,
        "rate": rate,
        "timeInMonths": timeInMonths,
        "startDate": _formatDate(startDate),
        "endDate": _formatDate(endDate),
        "type": "SIMPLE",
        "farmerId":farmerId
      }),
    );

    return _handleResponse(response);
  }

  // ---------------- COMPOUND INTEREST ----------------
  Future<InterestResult> calculateCompoundInterest({
    required double principal,
    required double rate,
    required int timeInMonths,
    required DateTime startDate,
    required DateTime endDate,
    required int compoundingFrequency,
  }) async {
    final auth = await _loadAuth();
    final int farmerId = int.parse(auth["farmerId"]!);
    final String token = auth["token"]!;
    final response = await http.post(
      Uri.parse("$baseUrl/interest/compound"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "principal": principal,
        "rate": rate,
        "timeInMonths": timeInMonths,
        "startDate": _formatDate(startDate),
        "endDate": _formatDate(endDate),
        "compoundingFrequency": compoundingFrequency,
        "type": "COMPOUND",
        "farmerId":farmerId,
      }),
    );

    return _handleResponse(response);
  }

  // ---------------- COMMON RESPONSE HANDLER ----------------
  InterestResult _handleResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception("Server error: ${response.statusCode}");
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (data["result"] != true) {
      throw Exception(data["message"] ?? "Calculation failed");
    }

    return InterestResult.fromJson(data["response"]);
  }

  Future<List<InterestHistory>> getInterestHistory() async {
    try {
      final auth = await _loadAuth();
      final farmerId = int.tryParse(auth["farmerId"] ?? '');
      final token = auth["token"];
      if (farmerId == null || token == null || token.isEmpty) {
        throw Exception("Invalid authentication data");
      }
      final uri = Uri.parse("$baseUrl/interest/histroy/$farmerId");

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Failed to load interest history");
      }

      final body = json.decode(utf8.decode(response.bodyBytes));
      if (body['result'] != true) {
        throw Exception(body['message'] ?? "Unknown error");
      }
      final List list = body['response'] ?? [];
      return list.map((e) => InterestHistory.fromJson(e)).toList();
    } catch (e, stack) {
      log(stack.toString());
      rethrow;
    }
  }

  Future<void> deleteHistory(int id) async {
    final auth = await _loadAuth();
    final token = auth["token"];
    if (token == null || token.isEmpty) {
      throw Exception("Invalid auth token");
    }
    final uri = Uri.parse("$baseUrl/interest/deleteHistory/$id");
    final response = await http.delete(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Failed to delete history");
    }
    log("Delete Successfully");
    final body = json.decode(response.body);
    if (body["result"] != true) {
      throw Exception(body["message"] ?? "Delete failed");
    }
  }

  Future<void> clearHistory() async {
    final auth = await _loadAuth();
    final token = auth["token"];
    final farmerId = int.tryParse(auth["farmerId"] ?? '');
    if (token == null || token.isEmpty) {
      throw Exception("Invalid auth token");
    }
    final uri = Uri.parse("$baseUrl/interest/deleteHistory/farmer/$farmerId");
    final response = await http.delete(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Failed to clear history");
    }
    final body = json.decode(response.body);
    if (body["result"] != true) {
      throw Exception(body["message"] ?? "Clear history failed");
    }
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }
}
