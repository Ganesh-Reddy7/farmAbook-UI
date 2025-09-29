import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/crop.dart';
import '../models/return_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/yearly_summary.dart';

class ReturnService {
  // Sample data
  final String baseUrl = "http://10.249.31.202:8080/api";

  final List<ReturnModel> _sampleReturns = [
    ReturnModel(year: 2019, description: "Wheat Sale", date: DateTime(2019, 3, 5), amount: 4000 ,quantity: 1),
    ReturnModel(year: 2020, description: "Rice Sale", date: DateTime(2020, 6, 12), amount: 6500 , quantity: 2),
    ReturnModel(year: 2021, description: "Vegetables Sale", date: DateTime(2021, 9, 18), amount: 5000 , quantity: 1),
    ReturnModel(year: 2022, description: "Fruits Sale", date: DateTime(2022, 11, 23), amount: 7000 , quantity: 1),
    ReturnModel(year: 2023, description: "Oilseeds Sale", date: DateTime(2023, 2, 10), amount: 9000 , quantity: 1),
  ];

  // Returns a summary of total returns per year
  Future<List<YearlyInvestmentSummaryDTO>> getYearlySummary({required int years}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final userData = prefs.getString("user_data");
    if (token == null || userData == null) return [];

    final user = jsonDecode(userData);
    final farmerId = user['id'];

    final uri = Uri.parse(
        "$baseUrl/returns/farmer/$farmerId/returns/yearly?year=$years"
    );

    final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
    });
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => YearlyInvestmentSummaryDTO.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> saveReturn({
    required double amount,
    required String description,
    required DateTime date,
    required int cropId,
    required double quantity
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final userData = prefs.getString("user_data");
    if (token == null || userData == null) {
      log("Token or user data missing");
      return false;
    }
    final formattedDate = "${date.year.toString().padLeft(4,'0')}-"
        "${date.month.toString().padLeft(2,'0')}-"
        "${date.day.toString().padLeft(2,'0')}";
    final user = jsonDecode(userData);
    final farmerId = user['id'];
    final body = jsonEncode({
      "farmerId": farmerId,
      "amount": amount,
      "description": description,
      "date": formattedDate,
      "cropId": cropId,
      "quantity":quantity,
    });
    log("GKaaxx :: body :: $body");
    final response = await http.post(
      Uri.parse("$baseUrl/returns"),
      headers: {"Content-Type": "application/json",
      "Authorization": "Bearer $token"},
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print("Failed to save return: ${response.body}");
      return false;
    }
  }
  Future<List<ReturnsList>> getReturnsByYear({required int year}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final userData = prefs.getString("user_data");
      final user = jsonDecode(userData!);
      final farmerId = user['id'];
      if (token == null || userData == null) {
        log("Token or user data missing");
        return [];
      }
      final response = await http.get(
        Uri.parse("$baseUrl/crops/$farmerId/crops/returns?year=$year"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        log("GKaaxx :: data :: $data");
        return data.map((json) => ReturnsList.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load returns. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching returns for year $year: $e");
      rethrow;
    }
  }

  Future<List<ReturnDetailModel>> getReturnsByCropAndYear({required int cropId ,required int year}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final userData = prefs.getString("user_data");
      final user = jsonDecode(userData!);
      final farmerId = user['id'];
      if (token == null || userData == null) {
        log("Token or user data missing");
        return [];
      }
      final response = await http.get(
        Uri.parse("$baseUrl/returns/farmer/$farmerId/crop/$cropId/returns?year=$year"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        log("GKaaxx :: data :: $data");
        return data.map((json) => ReturnDetailModel.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load returns. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching returns for year $year: $e");
      rethrow;
    }
  }
}




// Model for yearly summary
class YearlyReturnSummary {
  final int year;
  final double totalAmount;

  YearlyReturnSummary({required this.year, required this.totalAmount});
}
