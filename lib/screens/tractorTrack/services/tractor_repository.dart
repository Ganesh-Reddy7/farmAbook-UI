import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

class TractorYearlyStats {
  final int year;
  final double totalExpenses;
  final double totalReturns;
  final double fuelLitres;
  final double acresWorked;

  TractorYearlyStats({
    required this.year,
    required this.totalExpenses,
    required this.totalReturns,
    required this.fuelLitres,
    required this.acresWorked,
  });

  factory TractorYearlyStats.fromJson(Map<String, dynamic> json) {
    return TractorYearlyStats(
      year: json["year"],
      totalExpenses: (json["totalExpenses"] ?? 0).toDouble(),
      totalReturns: (json["totalReturns"] ?? 0).toDouble(),
      fuelLitres: (json["fuelLitres"] ?? 0).toDouble(),
      acresWorked: (json["acresWorked"] ?? 0).toDouble(),
    );
  }
}

class TractorRepository {
  String get baseUrl => dotenv.env['API_BASE_URL']!;
  Box get cache => Hive.box("farmAbook_cache");
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

  Future<TractorYearlyStats> fetchYearlyStats({required int year,}) async {
    final auth = await _loadAuth();
    final int farmerId = int.parse(auth["farmerId"]!);
    final String token = auth["token"]!;
    // final String cacheKey = "tractor_${farmerId}_$year";
    // if (cache.containsKey(cacheKey)) {
    //   final cached = cache.get(cacheKey);
    //   return TractorYearlyStats.fromJson(Map<String, dynamic>.from(cached));
    // }
    final url = Uri.parse("$baseUrl/tractor/yearly-stats?farmerId=$farmerId&startYear=$year&endYear=$year",);
    try {
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (res.statusCode != 200) {
        throw Exception("Failed to load stats: ${res.body}");
      }
      final decoded = jsonDecode(res.body);
      final data = decoded["yearlyData"][0];
      final stats = TractorYearlyStats.fromJson(data);
      // cache.put(cacheKey, data);
      return stats;
    } catch (e) {
      throw Exception("❌ Tractor stats load error: $e");
    }
  }
}
