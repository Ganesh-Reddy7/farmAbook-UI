import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/crop.dart';

class CropService {
  final String baseUrl = "https://yourapi.com/api/"; // replace with your API base URL

  /// Fetch list of crops for the current farmer
  Future<List<Crop>> getCrops() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final userData = prefs.getString("user_data");

      if (token == null || userData == null) return [];

      final farmerId = jsonDecode(userData)['id'];
      final url = Uri.parse("$baseUrl/crops?farmerId=$farmerId");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Crop.fromJson(e)).toList();
      } else {
        log("Get Crops failed: ${response.statusCode} ${response.body}");
        return [];
      }
    } catch (e) {
      log("Get Crops exception: $e");
      return [];
    }
  }

  /// Add a new crop
  Future<bool> addCrop({
    required String name,
    required double area,
    required DateTime plantedDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final userData = prefs.getString("user_data");

      if (token == null || userData == null) return false;

      final farmerId = jsonDecode(userData)['id'];

      final body = jsonEncode({
        "name": name,
        "plantedDate": "${plantedDate.year.toString().padLeft(4,'0')}-"
            "${plantedDate.month.toString().padLeft(2,'0')}-"
            "${plantedDate.day.toString().padLeft(2,'0')}",
        "area": area,
        "farmerId": farmerId,
      });

      final response = await http.post(
        Uri.parse("$baseUrl/crops"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      log("Add Crop status: ${response.statusCode}");
      log("Add Crop response: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      log("Add Crop exception: $e");
      return false;
    }
  }

  /// Update crop value (optional)
  Future<Crop?> updateCropValue(int cropId, double newValue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      if (token == null) return null;

      final url = Uri.parse("$baseUrl/crops/$cropId/value?value=$newValue");
      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return Crop.fromJson(jsonDecode(response.body));
      } else {
        log("Update Crop value failed: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      log("Update Crop exception: $e");
      return null;
    }
  }

  Future<List<Crop>> getCropsByYear(int year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final userData = prefs.getString("user_data");
      if (token == null || userData == null) return [];

      final farmerId = jsonDecode(userData)['id'];
      final url = Uri.parse("$baseUrl/crops?farmerId=$farmerId&year=$year");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Crop.fromJson(e)).toList();
      } else {
        log("Get Crops by year failed: ${response.statusCode} ${response.body}");
        return [];
      }
    } catch (e) {
      log("Get Crops by year exception: $e");
      return [];
    }
  }

  /// Get yearly summary (total value per year)
  Future<List<Map<String, dynamic>>> getYearlySummary({required int startYear, required int endYear}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final userData = prefs.getString("user_data");
      if (token == null || userData == null) return [];

      final farmerId = jsonDecode(userData)['id'];
      final url = Uri.parse("$baseUrl/crops/summary?farmerId=$farmerId&startYear=$startYear&endYear=$endYear");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        // Each element: {"year":2025,"totalValue":50000.0}
        return List<Map<String, dynamic>>.from(data);
      } else {
        log("Get yearly summary failed: ${response.statusCode} ${response.body}");
        return [];
      }
    } catch (e) {
      log("Get yearly summary exception: $e");
      return [];
    }
  }
}
