import 'package:budget_ai/models/expense.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const host = "backend-2xqnus4dqq-uc.a.run.app";
// const host = "127.0.0.1:5001";
const URI = Uri.https;
// const URI = Uri.http;
// const URL_PREFIX = "finbud-99269/us-central1/backend";
const URL_PREFIX = "";

getHeaders() async {
  String? bearer = await FirebaseAuth.instance.currentUser!.getIdToken();

  return {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $bearer'
  };
}

class ApiService {
  // Helper method to log requests and responses
  Future<http.Response> _makeRequest(String method, Uri url,
      Map<String, String> headers, String? body, String operationName) async {
    try {
      print("\n------- $operationName API CALL [$method] -------");
      print("URL: $url");
      print("Headers: $headers");
      if (body != null) {
        print("Request body: $body");
      }

      http.Response response;

      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: body);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers, body: body);
          break;
        case 'PATCH':
          response = await http.patch(url, headers: headers, body: body);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");
      print("------- END $operationName API CALL -------\n");

      return response;
    } catch (e) {
      print("API ERROR in $operationName: $e");
      print("------- END $operationName API CALL WITH ERROR -------\n");
      rethrow;
    }
  }

  Future<http.Response> fetchExpenses(
      DateTime fromDate, DateTime toDate) async {
    var uri = URI(host, '$URL_PREFIX/expenses', {
      "fromDate": fromDate.toUtc().toIso8601String(),
      "toDate": toDate.toUtc().toIso8601String()
    });

    final headers = await getHeaders();
    return _makeRequest('GET', uri, headers, null, 'FETCH_EXPENSES');
  }

  Future<http.Response> addExpense(userMessage, date,
      {double? latitude, double? longitude}) async {
    final uri = URI(host, '$URL_PREFIX/ai/expense');
    final headers = await getHeaders();
    final body = json.encode(<String, dynamic>{
      "userMessage": userMessage,
      "date": date != null ? date.toString() : "",
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });

    return _makeRequest('POST', uri, headers, body, 'AI_ADD_EXPENSE');
  }

  Future<http.Response> deleteExpense(id) async {
    final uri = URI(host, '$URL_PREFIX/expenses');
    final headers = await getHeaders();
    final body = json.encode(<String, String>{"id": id});

    return _makeRequest('DELETE', uri, headers, body, 'DELETE_EXPENSE');
  }

  Future<http.Response> updateExpense(Expense expense) async {
    final uri = URI(host, '$URL_PREFIX/expenses');
    final headers = await getHeaders();
    final body = json.encode(<String, Object>{"expense": expense.toJson()});

    return _makeRequest('PATCH', uri, headers, body, 'UPDATE_EXPENSE');
  }

  // Method for manually creating expense through API
  Future<http.Response> createExpense(Expense expense) async {
    final uri = URI(host, '$URL_PREFIX/expenses');
    final headers = await getHeaders();

    // Create request body with the proper structure
    final requestBody = json.encode({
      "expense": {
        "category": expense.category,
        "date": expense.datetime.toUtc().toIso8601String(),
        "description": expense.description,
        "amount": expense.amount,
        if (expense.latitude != null) 'latitude': expense.latitude,
        if (expense.longitude != null) 'longitude': expense.longitude,
      }
    });

    return _makeRequest(
        'POST', uri, headers, requestBody, 'MANUAL_CREATE_EXPENSE');
  }

  // Method to report an AI-generated expense as incorrect
  Future<http.Response> reportAIExpense(Expense expense,
      {String? message}) async {
    final uri = URI(host, '$URL_PREFIX/report-ai-expense');
    final headers = await getHeaders();
    final body = json.encode({
      "expense": expense.toJson(),
      if (message != null && message.isNotEmpty) "message": message,
    });
    return _makeRequest('POST', uri, headers, body, 'REPORT_AI_EXPENSE');
  }
}
