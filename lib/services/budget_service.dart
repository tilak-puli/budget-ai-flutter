import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

// Base API constants
const host = "backend-2xqnus4dqq-uc.a.run.app";
const URI = Uri.https;
const URL_PREFIX = "";

class BudgetService {
  // Get auth headers with Firebase token
  Future<Map<String, String>> _getHeaders() async {
    String? bearer = await FirebaseAuth.instance.currentUser!.getIdToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $bearer'
    };
  }

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
          response = await http.delete(url, headers: headers);
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

  // Get user budget configuration
  Future<Map<String, dynamic>> getUserBudget() async {
    try {
      final headers = await _getHeaders();
      final uri = URI(host, '$URL_PREFIX/budgets');

      final response =
          await _makeRequest('GET', uri, headers, null, 'GET_USER_BUDGET');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load budget: ${response.statusCode}');
        return {
          'success': false,
          'errorMessage': 'Failed to load budget: ${response.statusCode}'
        };
      }
    } catch (e) {
      print("Error getting user budget: $e");
      return {
        'success': false,
        'errorMessage': 'Error getting user budget: $e'
      };
    }
  }

  // Set total monthly budget
  Future<Map<String, dynamic>> setTotalBudget(double amount) async {
    try {
      final headers = await _getHeaders();
      final uri = URI(host, '$URL_PREFIX/budgets/total');
      final body = json.encode({'totalBudget': amount});

      final response =
          await _makeRequest('POST', uri, headers, body, 'SET_TOTAL_BUDGET');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to set total budget: ${response.statusCode}');
      }
    } catch (e) {
      print("Error setting total budget: $e");
      rethrow;
    }
  }

  // Set category budget
  Future<Map<String, dynamic>> setCategoryBudget(
      String category, double amount) async {
    try {
      final headers = await _getHeaders();
      final uri = URI(host, '$URL_PREFIX/budgets/category');
      final body = json.encode({'category': category, 'amount': amount});

      final response =
          await _makeRequest('POST', uri, headers, body, 'SET_CATEGORY_BUDGET');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to set category budget: ${response.statusCode}');
      }
    } catch (e) {
      print("Error setting category budget: $e");
      rethrow;
    }
  }

  // Set multiple category budgets
  Future<Map<String, dynamic>> setMultipleCategoryBudgets(
      Map<String, double> categoryBudgets) async {
    try {
      final headers = await _getHeaders();
      final uri = URI(host, '$URL_PREFIX/budgets/categories');
      final body = json.encode({'categoryBudgets': categoryBudgets});

      final response = await _makeRequest(
          'POST', uri, headers, body, 'SET_MULTIPLE_BUDGETS');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to set multiple budgets: ${response.statusCode}');
      }
    } catch (e) {
      print("Error setting multiple category budgets: $e");
      rethrow;
    }
  }

  // Get budget summary with spending comparison
  Future<Map<String, dynamic>> getBudgetSummary({int? month, int? year}) async {
    try {
      final headers = await _getHeaders();

      // Build query parameters
      final queryParams = <String, String>{};
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();

      final uri = URI(host, '$URL_PREFIX/budgets/summary', queryParams);

      final response =
          await _makeRequest('GET', uri, headers, null, 'GET_BUDGET_SUMMARY');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to get budget summary: ${response.statusCode}');
        return {
          'success': false,
          'errorMessage': 'Failed to get budget summary: ${response.statusCode}'
        };
      }
    } catch (e) {
      print("Error getting budget summary: $e");
      return {
        'success': false,
        'errorMessage': 'Error getting budget summary: $e'
      };
    }
  }

  // Delete user budget
  Future<Map<String, dynamic>> deleteBudget() async {
    try {
      final headers = await _getHeaders();
      final uri = URI(host, '$URL_PREFIX/budgets');

      final response =
          await _makeRequest('DELETE', uri, headers, null, 'DELETE_BUDGET');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete budget: ${response.statusCode}');
      }
    } catch (e) {
      print("Error deleting budget: $e");
      rethrow;
    }
  }
}
