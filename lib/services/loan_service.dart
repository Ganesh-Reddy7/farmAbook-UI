import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../models/PaymentHistoryDTO.dart';
import '../models/lentDto.dart';

class LoanService {
  final String baseUrl = "http://10.205.90.202:8080/api";

  Future<bool> addLentLoan({
    required String source,
    required double amount,
    required double interest,
    required DateTime startDate,
    required int maturityYears,
    required String description,
    required bool isGiven
  }) async {
    try {
      final formattedDate =
          "${startDate.year.toString().padLeft(4, '0')}-"
          "${startDate.month.toString().padLeft(2, '0')}-"
          "${startDate.day.toString().padLeft(2, '0')}";

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final userData = prefs.getString("user_data");

      if (token == null || userData == null) {
        log("Token or user data missing");
        return false;
      }

      final user = jsonDecode(userData);
      final userId = user['id'];

      final body = jsonEncode({
        "farmerId": userId,
        "source": source,
        "principal": amount,
        "interestRate": interest,
        "startDate": formattedDate,
        "maturityPeriodYears": maturityYears,
        "description": description,
        "isGiven":isGiven
      });

      final response = await http.post(
        Uri.parse("$baseUrl/loans"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );

      log("Add Lent Loan status: ${response.statusCode}");
      log("Add Lent Loan response: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      log("Add Lent Loan exception: $e");
      return false;
    }
  }

  Future<List<LentLoanDTO>> getLentLoansForFarmer({required isGiven}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final userData = prefs.getString("user_data");

      if (token == null || userData == null) {
        log("Token or user data missing");
        return [];
      }

      final user = jsonDecode(userData);
      final farmerId = user['id'];

      final uri = Uri.parse("$baseUrl/loans/farmer/$farmerId/type?isGiven=$isGiven");

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("Lent Loans Response: ${response.body}");

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => LentLoanDTO.fromJson(e)).toList();
      } else {
        log("Failed to fetch lent loans: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      log("Exception fetching lent loans: $e");
      return [];
    }
  }

  Future<List<LentLoanDTO>> getLoansForFarmer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final userData = prefs.getString("user_data");

      if (token == null || userData == null) {
        log("Token or user data missing");
        return [];
      }

      final user = jsonDecode(userData);
      final farmerId = user['id'];

      final uri = Uri.parse("$baseUrl/loans/farmer/$farmerId");

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      log("Lent Loans Response: ${response.body}");

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => LentLoanDTO.fromJson(e)).toList();
      } else {
        log("Failed to fetch lent loans: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      log("Exception fetching lent loans: $e");
      return [];
    }
  }

   Future<bool> addPayment(int loanId, double amount, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final userData = prefs.getString("user_data");

      final url = Uri.parse("$baseUrl/loans/payment");
      final formattedDate =
          "${date.year.toString().padLeft(4, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.day.toString().padLeft(2, '0')}";

      if (token == null || userData == null) {
        log("Token or user data missing");
        return false;
      }
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'paymentDate': formattedDate,
          'id': loanId
        }),
      );
      log("GKaaxx :: response :: $response");
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Error adding payment: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception adding payment: $e');
      return false;
    }
  }

  Future<bool> closeLoan(int loanId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      if (token == null) {
        log("Token or user data missing");
        return false;
      }

      final url = Uri.parse('$baseUrl/loans/$loanId/close');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        log('Error closing loan: ${response.body}');
        return false;
      }
    } catch (e) {
      log('Exception closing loan: $e');
      return false;
    }
  }

  Future<List<PaymentHistoryDTO>> getPaymentHistory(int loanId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null) return [];

      final uri = Uri.parse("$baseUrl/loans/$loanId/raw-payments");

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        log("GKaaxx :: data :: $data");
        return data.map((e) => PaymentHistoryDTO.fromJson(e)).toList();
      }else{
        log('Error closing loan: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching payment history: $e");
      return [];
    }
  }

}

