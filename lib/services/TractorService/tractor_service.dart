import 'dart:convert';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/Tractor.dart';
import '../../models/expense.dart';
import '../../utils/cache_manager.dart';

class TractorService {
  final String? baseUrl = dotenv.env['API_BASE_URL'];

  // ---------------------------------------------------------------------------
  // COMMON: Load token + farmerId
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // ADD TRACTOR
  // ---------------------------------------------------------------------------
  Future<http.Response> addTractor(Map<String, dynamic> tractorData) async {
    final auth = await _loadAuth();
    final url = Uri.parse('$baseUrl/tractor/addTractor');

    final body = {
      ...tractorData,
      "farmerId": auth["farmerId"],
    };

    log("Adding tractor => $body");

    try {
      return await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
        body: jsonEncode(body),
      );
    } catch (e) {
      throw Exception("Network error while adding tractor: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // FETCH ALL TRACTORS WITH DETAILS (profit, trips, fuel etc.)
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchTractors() async {
    final auth = await _loadAuth();
    final url = Uri.parse(
      "$baseUrl/tractor/farmer/${auth["farmerId"]}/getTractorDetails",
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
      );
      if (response.statusCode != 200) {
        throw Exception("Failed to load tractors: ${response.statusCode}");
      }

      final List<dynamic> list = jsonDecode(response.body);
      if (list.isEmpty) return [];

      return list.map<Map<String, dynamic>>((t) {
        return {
          'tractorId': (t['tractorId'] ?? 0),
          'serialNumber': t['serialNumber'] ?? '-',
          'model': t['model'] ?? 'Unknown Model',
          'make': t['make'] ?? 'N/A',
          'capacityHp': (t['capacityHp'] ?? 0).toDouble(),
          'status': t['status'] ?? 'Inactive',
          'totalExpenses': (t['totalExpenses'] ?? 0).toDouble(),
          'totalReturns': (t['totalReturns'] ?? 0).toDouble(),
          'netProfit': (t['netProfit'] ?? 0).toDouble(),
          'totalAreaWorked': (t['totalAreaWorked'] ?? 0).toDouble(),
          'totalTrips': (t['totalTrips'] ?? 0),
          'totalFuelLitres': (t['totalFuelLitres'] ?? 0).toDouble(),
        };
      }).toList();
    } catch (e) {
      log("❌ Error fetching tractors: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // GET LIST OF ACTIVE TRACTORS (for dropdowns)
  // ---------------------------------------------------------------------------
  Future<List<Tractor>> getTractorList() async {
    final auth = await _loadAuth();
    final url = Uri.parse('$baseUrl/tractor/farmer/${auth["farmerId"]}');

    log("Fetching active tractor list from: $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
      );

      if (response.statusCode != 200) {
        log("❌ Failed to load tractor list: ${response.statusCode}");
        return [];
      }

      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((e) => Tractor.fromJson(e))
          .where((t) => t.status.toLowerCase() == "active")
          .toList();
    } catch (e) {
      log("❌ Error fetching tractor list: $e");
      return [];
    }
  }

  Future<http.Response> addTractorExpense(
      Map<String, dynamic> expenseData) async {
    final auth = await _loadAuth();
    final url = Uri.parse('$baseUrl/tractor-expenses');

    // Build final request body
    final body = {
      "tractorId": expenseData["tractorId"],
      "expenseDate": expenseData["expenseDate"],
      "type": expenseData["type"],
      "litres": expenseData["litres"] ?? 0,
      "cost": expenseData["cost"],
      "notes": expenseData["notes"],
      "farmerId": auth["farmerId"],
    };

    log("Adding Tractor Expense => ${jsonEncode(body)}");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
        body: jsonEncode(body),
      );
      AppCacheManager.clearTractorCache(auth["farmerId"] as int);
      log("Expense API Response: ${response.statusCode} → ${response.body}");
      return response;
    } catch (e) {
      throw Exception("Network error while adding expense: $e");
    }
  }

  // ----------------------------------------------------------
  // ADD CLIENT
  // ----------------------------------------------------------
  Future<http.Response> addClient(Map<String, dynamic> clientData) async {
    final auth = await _loadAuth();
    final url = Uri.parse("$baseUrl/tractor-clients");
    final body = {
      "farmerId": auth["farmerId"],
      "name": clientData["name"],
      "phone": clientData["phone"],
      "address": clientData["address"] ?? "",
      "notes": clientData["notes"] ?? ""
    };
    log("Adding Client ⇒ ${jsonEncode(body)}");
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
        body: jsonEncode(body),
      );
      log("API Response: ${response.statusCode} → ${response.body}");
      return response;
    } catch (e) {
      throw Exception("❌ Network error while adding client: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final auth = await _loadAuth();
    final url = Uri.parse(
        '${baseUrl}/tractor-clients/farmer/${auth["farmerId"]}');
    log("Fetching clients → $url");
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
      );

      log("Clients Response: ${response.body}");

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);

      return data.map((c) {
        return {
          "id": c["id"] ?? 0,
          "name": c["name"] ?? "Unknown",
          "totalAmount": (c["totalAmount"] ?? 0).toDouble(),
          "pendingAmount": (c["pendingAmount"] ?? 0).toDouble(),
          "totalAcresWorked": (c["totalAcresWorked"] ?? 0).toDouble(),
          "totalTrips": c["totalTrips"] ?? 0,
          "phone": c["phone"]
        };
      }).toList();
    } catch (e) {
      log("❌ Error loading clients: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> getClientActivities(int clientId) async {
    final auth = await _loadAuth();

    final url = Uri.parse(
        "$baseUrl/tractor-clients/client/$clientId/activities");
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
      );
      log("Activities Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load client activities");
      }
    } catch (e) {
      throw Exception("Network error while fetching client activities: $e");
    }
  }

  // ---------------------------------------------------------------------------
// 🔹 ADD RETURN (Activity Entry)
// ---------------------------------------------------------------------------
  Future<http.Response> addReturn(Map<String, dynamic> returnData) async {
    try {
      final auth = await _loadAuth();
      final url = Uri.parse('$baseUrl/tractor-activities/create');

      final body = {
        "tractorId": returnData["tractorId"],
        "farmerId": auth["farmerId"],
        "activityDate": returnData["activityDate"],
        "startTime": returnData["startTime"],
        "endTime": returnData["endTime"],
        "clientName": returnData["clientName"],
        "acresWorked": returnData["acresWorked"],
        "amountEarned": returnData["amountEarned"],
        "notes": returnData["notes"],
        "clientId": returnData["clientId"] ?? 0,
      };

      log("ADD RETURN → ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
        body: jsonEncode(body),
      );

      log("ADD RETURN RESPONSE → ${response.statusCode} | ${response.body}");
      return response;
    } catch (e) {
      log("addReturn() error → $e");
      throw Exception("Network error while sending return data: $e");
    }
  }

  Future<http.Response> addClosePayment({required int activityId, required double paymentAmount}) async {
    final auth = await _loadAuth();
    final url = Uri.parse("$baseUrl/tractor-activities/add-payment?activityId=$activityId&paymentAmount=$paymentAmount");
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
        // body: jsonEncode(body),
      );
      log("API Response: ${response.statusCode} → ${response.body}");
      return response;
    } catch (e) {
      throw Exception("❌ Network error while adding client: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getYearlyExpenses({required int startYear, required int endYear}) async {
    final auth = await _loadAuth();
    final dynamic farmerIdRaw = auth["farmerId"];
    final int farmerId = int.tryParse(farmerIdRaw.toString()) ?? 0;
    final url = Uri.parse(
        "$baseUrl/tractor-expenses/expense-trend-range?farmerId=$farmerId&startYear=$startYear&endYear=$endYear");
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
      );
      if (response.statusCode != 200) {
        throw Exception("Failed: ${response.body}");
      }
      final decoded = jsonDecode(response.body);
      final yearly = decoded["yearlyData"] as List<dynamic>? ?? [];
      return yearly.map<Map<String, dynamic>>((raw) {
        return {
          "year": int.tryParse(raw["year"].toString()) ?? 0,
          "totalYearExpense": double.tryParse(raw["totalYearExpense"].toString()) ?? 0.0,
          "monthlyExpenses": raw["monthlyExpenses"] ?? [],
        };
      }).toList();
    } catch (e) {
      throw Exception("❌ Yearly expenses load error: $e");
    }
  }

  Future<Map<String, int>> getExpenseSummary() async {
    final auth = await _loadAuth();
    final farmerId = int.tryParse(auth["farmerId"]?.toString() ?? "0") ?? 0;
    final url = Uri.parse("$baseUrl/tractor-expenses/farmer/$farmerId/summary");
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        return {
          "fuelExpense": (decoded["fuelExpense"] ?? 0).toInt(),
          "repairExpense": (decoded["repairExpense"] ?? 0).toInt(),
          "otherExpense": (decoded["otherExpense"] ?? 0).toInt(),
          "totalExpense": (decoded["totalExpense"] ?? 0).toInt(),
        };
      } else {
        throw Exception("Failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("❌ Expense summary load error: $e");
    }
  }

  Future<List<Expense>> getExpenses({required String filter, int? year, int? month,}) async {
    final auth = await _loadAuth();
    final dynamic farmerIdRaw = auth["farmerId"];
    final int farmerId = int.tryParse(farmerIdRaw.toString()) ?? 0;
    String base = "$baseUrl/tractor-expenses/farmer";
    late Uri url;
    if (filter == "monthly") {
      url = Uri.parse("$base/year-month-wise/$farmerId?year=$year&month=$month");
    }
    else if (filter == "yearly") {
      url = Uri.parse(
          "$base/year-month-wise/$farmerId?year=$year"
      );
    }
    else {
      url = Uri.parse("$base/year-month-wise/$farmerId");
    }
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
      );
      if (response.statusCode != 200) {
        throw Exception("Failed: ${response.body}");
      }
      final list = jsonDecode(response.body) as List<dynamic>;

      return list.map((e) => Expense.fromJson(e)).toList();
    } catch (e) {
      throw Exception("❌ Expenses load error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getYearlyReturns({required int startYear, required int endYear, bool? isSummary,}) async {
    final auth = await _loadAuth();
    final dynamic farmerIdRaw = auth["farmerId"];
    final int farmerId = int.tryParse(farmerIdRaw.toString()) ?? 0;
    final url = Uri.parse("$baseUrl/tractor-activities/trend/range/$farmerId?startYear=$startYear&endYear=$endYear");
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Failed: ${response.body}");
      }

      final decoded = jsonDecode(response.body);
      final yearly = decoded["yearlyData"] as List<dynamic>? ?? [];

      return yearly.map<Map<String, dynamic>>((raw) {
        final map = <String, dynamic>{
          "year": int.tryParse(raw["year"].toString()) ?? 0,
          "totalYearAmount": double.tryParse(raw["totalYearAmount"].toString()) ?? 0.0,
          "monthlyActivities": raw["monthlyActivities"] ?? [],
        };
        if (isSummary == true) {
          map["totalYearAmount"] = raw["totalYearAmount"] ?? 0;
          map["totalYearReceived"] = double.tryParse(raw["totalYearReceived"].toString()) ?? 0.0;
          map["totalYearRemaining"] = raw["totalYearRemaining"] ?? "";
          map["totalYearAcres"] = raw["totalYearAcres"] ?? "";
        }
        return map;
      }).toList();
    } catch (e) {
      throw Exception("❌ Yearly expenses load error: $e");
    }
  }

  Future<Map<String, dynamic>> getReturns({required String filter, int? year, int? month}) async {
    final auth = await _loadAuth();
    final dynamic farmerIdRaw = auth["farmerId"];
    final int farmerId = int.tryParse(farmerIdRaw.toString()) ?? 0;
    String base = "$baseUrl/tractor-activities/farmer/year-month-wise/$farmerId/activities";
    late Uri url;
    if (filter == "monthly") {
      url = Uri.parse("$base?year=$year&month=$month");
    }
    else if (filter == "yearly") {
      url = Uri.parse("$base?year=$year");
    }
    else {
      url = Uri.parse("$base");
    }
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
      );
      if (response.statusCode != 200) {
        throw Exception("Failed: ${response.body}");
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        throw Exception("Invalid Returns API response format");
      }
    } catch (e) {
      throw Exception("❌ Returns load error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getYearlySummary({required int startYear, required int endYear}) async {
    final auth = await _loadAuth();
    final dynamic farmerIdRaw = auth["farmerId"];
    final int farmerId = int.tryParse(farmerIdRaw.toString()) ?? 0;
    final url = Uri.parse("$baseUrl/tractor/yearly-stats?farmerId=$farmerId&startYear=$startYear&endYear=$endYear");
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
      );
      if (response.statusCode != 200) {
        throw Exception("Failed: ${response.body}");
      }
      final decoded = jsonDecode(response.body);
      final yearly = decoded["yearlyData"] as List<dynamic>? ?? [];

      return yearly.map<Map<String, dynamic>>((raw) {
        final map = <String, dynamic>{
          "year": int.tryParse(raw["year"].toString()) ?? 0,
          "totalExpenses": double.tryParse(raw["totalExpenses"].toString()) ?? 0.0,
          "totalReturns": double.tryParse(raw["totalReturns"].toString()) ?? 0.0,
          "acresWorked": double.tryParse(raw["acresWorked"].toString()) ?? 0.0,
          "fuelLitres": double.tryParse(raw["fuelLitres"].toString()) ?? 0.0,
          "totalProfit": double.tryParse((raw["totalReturns"] - raw["totalExpenses"]).toString()) ?? 0.0
        };
        return map;
      }).toList();
    } catch (e) {
      throw Exception("❌ Yearly expenses load error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyTractorStats({required int year,  int? tractorId}) async {
    final auth = await _loadAuth();
    final dynamic farmerIdRaw = auth["farmerId"];
    final int farmerId = int.tryParse(farmerIdRaw.toString()) ?? 0;
    String base = "$baseUrl/tractor/monthly?farmerId=$farmerId&year=$year";
    late Uri url;
    if(tractorId != null){
      url = Uri.parse("$base?tractorId=$tractorId");
    }else{
      url = Uri.parse("$base");
    }
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth["token"]}",
        },
      );
      if (response.statusCode != 200) {
        throw Exception("Failed: ${response.body}");
      }
      final decoded = jsonDecode(response.body);
      log("GKaaaxx :: decode :: $decoded");
      final yearly = decoded["monthlyData"] as List<dynamic>? ?? [];

      return yearly.map<Map<String, dynamic>>((raw) {
        final map = <String, dynamic>{
          "month": (raw["month"].toString()),
          "returnsAmount": double.tryParse(raw["returnsAmount"].toString()) ?? 0.0,
          "expenseAmount": double.tryParse(raw["expenseAmount"].toString()) ?? 0.0,
          "acresWorked": double.tryParse(raw["acresWorked"].toString()) ?? 0.0,
          "fuelLitres": double.tryParse(raw["fuelLitres"].toString()) ?? 0.0,
          "totalProfit": double.tryParse((raw["returnsAmount"] - raw["expenseAmount"]).toString()) ?? 0.0
        };
        return map;
      }).toList();
    } catch (e) {
      throw Exception("❌ Monthly expenses load error: $e");
    }
  }

}