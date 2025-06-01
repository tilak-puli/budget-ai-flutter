import 'dart:convert';
import 'package:coin_master_ai/models/app_init_response.dart';
import 'package:coin_master_ai/models/expense_list.dart';
import 'package:coin_master_ai/models/expense.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

// Base API constants
const host = "backend-2xqnus4dqq-uc.a.run.app";
const URI = Uri.https;
const URL_PREFIX = "";

class AppInitService {
  // Singleton pattern
  static final AppInitService _instance = AppInitService._internal();
  factory AppInitService() => _instance;
  AppInitService._internal();

  // Cached data
  AppInitResponse? _cachedData;

  // Getter for cached data
  AppInitResponse? get cachedData => _cachedData;

  // Get auth headers with Firebase token
  Future<Map<String, String>> _getHeaders() async {
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // Helper method to log requests and responses
  Future<http.Response> _makeRequest(
    String method,
    Uri url,
    Map<String, String> headers,
    String? body,
    String operationName,
  ) async {
    try {
      developer.log("\n------- $operationName API CALL [$method] -------");
      developer.log("URL: $url");
      developer.log("Headers: $headers");
      if (body != null) {
        developer.log("Request body: $body");
      }

      http.Response response;

      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: body);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      developer.log("Response status: ${response.statusCode}");
      developer.log(
        "Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...",
      );
      developer.log("------- END $operationName API CALL -------\n");

      return response;
    } catch (e) {
      developer.log("API ERROR in $operationName: $e");
      developer.log("------- END $operationName API CALL WITH ERROR -------\n");
      rethrow;
    }
  }

  // Fetch app initialization data
  Future<AppInitResponse?> fetchAppInitData({
    DateTime? fromDate,
    DateTime? toDate,
    bool forceRefresh = false,
  }) async {
    // Check for cached data first if not forcing refresh
    if (!forceRefresh && _cachedData != null) {
      developer.log('Using cached app init data');
      return _cachedData;
    }

    // Check for cached data in storage
    if (!forceRefresh) {
      final storageData = await getAppInitDataFromStorage();

      if (storageData != null) {
        // Check if data is fresh (less than 1 hour old)
        final lastUpdated = storageData['lastUpdated'] as String?;
        if (lastUpdated != null) {
          final lastUpdateTime = DateTime.parse(lastUpdated);
          final now = DateTime.now();
          if (now.difference(lastUpdateTime).inMinutes < 60) {
            developer.log(
              'App init data is fresh, using cached data from storage',
            );
            try {
              _cachedData = AppInitResponse.fromJson(storageData['data'] ?? {});
              return _cachedData;
            } catch (e) {
              developer.log('Error parsing cached app init data: $e');
              // If parsing fails, continue with fetching fresh data
            }
          }
        }
      }
    }

    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (fromDate != null) {
        queryParams['fromDate'] = fromDate.toUtc().toIso8601String();
      }
      if (toDate != null) {
        queryParams['toDate'] = toDate.toUtc().toIso8601String();
      }

      final uri = URI(host, '$URL_PREFIX/init', queryParams);
      final headers = await _getHeaders();

      developer.log('Calling unified app init API: $uri');
      final response = await _makeRequest(
        'GET',
        uri,
        headers,
        null,
        'APP_INIT',
      );

      if (response.statusCode == 200) {
        try {
          final data =
              json.decode(response.body) as Map<String, dynamic>? ?? {};
          developer.log('App init API response received successfully');

          // Store the raw response in shared preferences with timestamp
          final storageData = {
            'data': data,
            'lastUpdated': DateTime.now().toIso8601String(),
          };
          await storeAppInitDataInStorage(storageData);

          _cachedData = AppInitResponse.fromJson(data);
          return _cachedData;
        } catch (e) {
          developer.log('Error parsing app init API response: $e');
          return null;
        }
      } else {
        developer.log(
          'App init API error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      developer.log('Error calling app init API: $e');
      return null;
    }
  }

  // Convert init data to expenses list
  Expenses getExpensesFromInitData(AppInitResponse initData) {
    final sortedExpenses = List<Expense>.from(initData.expenses);
    sortedExpenses.sort((a, b) => b.datetime.compareTo(a.datetime));
    return Expenses(sortedExpenses);
  }

  // Store app init data in shared preferences
  Future<void> storeAppInitDataInStorage(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(data);
      await prefs.setString('app_init_data', jsonStr);
      developer.log('App init data stored in local storage');
    } catch (e) {
      developer.log('Error storing app init data: $e');
    }
  }

  // Retrieve app init data from shared preferences
  Future<Map<String, dynamic>?> getAppInitDataFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('app_init_data');

      if (jsonStr == null || jsonStr.isEmpty) {
        return null;
      }

      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      developer.log('Error retrieving app init data: $e');
      return null;
    }
  }

  // Clear cached data
  Future<void> clearCache() async {
    _cachedData = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_init_data');
    developer.log('App init data cache cleared');
  }
}
