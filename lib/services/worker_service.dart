import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/investment.dart';
import 'session_service.dart'; // Make sure you have this service to get the token
import 'package:shared_preferences/shared_preferences.dart';


class WorkerService {
  String baseUrl = "http://10.94.67.202:8080/api";

  /// Toggle payment status (paid ↔ unpaid)
  Future<Worker?> updateWorkerPayment(int workerId, bool newStatus) async {
    try {
      // Get token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      if (token == null) return null;

      // Send paymentDone as query parameter
      final url = Uri.parse("$baseUrl/workers/$workerId/payment?paymentDone=$newStatus");

      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Worker.fromJson(data);
      } else {
        print("Update Worker Payment failed: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      rethrow;
    }
  }



  /// Fetch workers for an investment
  Future<List<Worker>> fetchWorkersByInvestment(int investmentId) async {
    try {
      String? token = await SessionService().getToken();
      if (token == null) return [];

      final url = Uri.parse("$baseUrl/investments/$investmentId/workers");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((w) => Worker.fromJson(w)).toList();
      } else {
        print("Fetch Workers failed: ${response.statusCode} ${response.body}");
        return [];
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Add a new worker to an investment
  Future<Worker?> addWorker(Worker worker, int investmentId) async {
    try {
      String? token = await SessionService().getToken();
      if (token == null) return null;

      final url = Uri.parse("$baseUrl/investments/$investmentId/workers");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(worker.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Worker.fromJson(data);
      } else {
        print("Add Worker failed: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a worker
  Future<bool> deleteWorker(int workerId) async {
    try {
      String? token = await SessionService().getToken();
      if (token == null) return false;

      final url = Uri.parse("$baseUrl/workers/$workerId");
      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode != 204) {
        print("Delete Worker failed: ${response.statusCode} ${response.body}");
      }

      return response.statusCode == 204;
    } catch (e) {
      rethrow;
    }
  }
}
