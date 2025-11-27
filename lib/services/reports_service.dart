import 'dart:convert';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/CropData.dart';
import '../models/SummaryData.dart';
import '../models/user.dart';
import 'session_service.dart';

class ReportsService {
  final String? baseUrl = dotenv.env['API_BASE_URL'];

  /// Get report data for top cards and tab content
  Future<Map<String, dynamic>?> getReports({required User farmer, required int year}) async {
    try {
      String? token = await SessionService().getToken();
      if (token == null) return null;
      final response = await http.post(
        Uri.parse("${baseUrl}/reports/farmer/yearly?farmerId=${farmer.farmerId}&year=$year"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Reports API failed: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      print("Reports API exception: $e");
      return null;
    }
  }

  Future<List<SummaryData>?> getYearlyReports({required int year}) async {
    try {
      String? token = await SessionService().getToken();
      User? userDetails = await SessionService().getUser();
      int? farmerId= userDetails?.farmerId;
      if (token == null) return null;

      final response = await http.get(
        Uri.parse(
          "${baseUrl}/reports/farmer/$farmerId/overview?lastYears=$year",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SummaryData.fromJson(json)).toList();
      } else {
        print("Reports API failed: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      print("Reports API exception: $e");
      return null;
    }
  }

  Future<Map<String, List<CropData>>> getCropsDistributionData({required int year}) async {
    String? token = await SessionService().getToken();
    User? userDetails = await SessionService().getUser();
    int? farmerId = userDetails?.farmerId;

    if (token == null || farmerId == null) return {'topCrops': [], 'lowCrops': []};

    final Uri url = year == 0
        ? Uri.parse("${baseUrl}/crops/$farmerId")
        : Uri.parse("${baseUrl}/crops/$farmerId?year=$year");
    log("GKaaxx :: url :: $url");
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<CropData> topCrops = [];
        List<CropData> lowCrops = [];

        if (data['topCrops'] != null) {
          topCrops = (data['topCrops'] as List)
              .map((json) => CropData.fromJson(json))
              .toList();
        }

        if (data['lowCrops'] != null) {
          lowCrops = (data['lowCrops'] as List)
              .map((json) => CropData.fromJson(json))
              .toList();
        }

        return {
          'topCrops': topCrops,
          'lowCrops': lowCrops,
        };
      } else {
        print("Failed to load crops data: ${response.statusCode}");
        return {'topCrops': [], 'lowCrops': []};
      }
    } catch (e) {
      print("Error fetching crops data: $e");
      return {'topCrops': [], 'lowCrops': []};
    }
  }

}
