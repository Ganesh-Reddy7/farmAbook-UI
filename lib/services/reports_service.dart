import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'session_service.dart';

class ReportsService {
  final String baseUrl = "http://10.94.67.202:8080/api/";

  /// Get report data for top cards and tab content
  Future<Map<String, dynamic>?> getReports({required User farmer, required int year}) async {
    try {
      String? token = await SessionService().getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse("${baseUrl}reports/farmer/yearly?farmerId=${farmer.farmerId}&year=$year"),
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
}
