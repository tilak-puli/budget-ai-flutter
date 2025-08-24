import 'package:finly/services/budget_service.dart';
import 'package:finly/services/subscription_service.dart';
import 'package:finly/services/app_init_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:finly/models/app_init_response.dart';
import 'package:finly/models/expense.dart';
import 'package:finly/state/budget_store.dart';
import 'package:finly/state/expense_store.dart';
import 'package:finly/state/chat_store.dart';

// Base API constants
const host = "backend-2xqnus4dqq-uc.a.run.app";
const URI = Uri.https;
const URL_PREFIX = "";

class InitializationService {
  final BudgetService _budgetService = BudgetService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final AppInitService _appInitService = AppInitService();

  // Cached data after initialization
  AppInitResponse? _appInitData;

  // Getter for the cached init data
  AppInitResponse? get appInitData => _appInitData;

  // Track initialization state
  bool _initialized = false;
  bool _initializing = false;
  String? _error;

  // Getters
  bool get isInitialized => _initialized;
  bool get isInitializing => _initializing;
  String? get error => _error;

  // Initialize app data - called at app startup
  Future<bool> initializeAppData({DateTime? fromDate, DateTime? toDate}) async {
    // Skip if already initializing
    if (_initializing) {
      return _initialized;
    }

    _initializing = true;
    _error = null;

    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log('User not logged in, skipping data initialization');
        _initialized = false;
        _initializing = false;
        return false;
      }

      // Use the AppInitService to fetch unified data
      final result = await _appInitService.fetchAppInitData(
        fromDate: fromDate,
        toDate: toDate,
      );

      if (result != null) {
        _appInitData = result;
        _initialized = true;

        // Store the response data in relevant stores
        await _storeAppInitData(result);

        developer.log('App data successfully initialized using unified API');
        return true;
      } else {
        // If the unified API fails, fall back to the existing methods
        developer.log(
          'Unified API failed, falling back to individual API calls',
        );
        await Future.wait([_prefetchBudgetData(), _prefetchQuotaData()]);

        _initialized = true;
        return true;
      }
    } catch (e) {
      _error = 'Error initializing app data: $e';
      developer.log(_error!);
      _initialized = false;
      return false;
    } finally {
      _initializing = false;
    }
  }

  // Store the app init data in various storage locations
  Future<void> _storeAppInitData(AppInitResponse data) async {
    // Store budget data
    if (data.budget.budgetExists && data.budget.budget != null) {
      final budgetData = {
        'success': true,
        'budget': data.budget.budget!.toJson(),
        'categories': data.budget.categories,
        'budgetExists': data.budget.budgetExists,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      await storeBudgetDataInStorage(budgetData);
    }

    // Store quota data
    final subscriptionData = {
      'hasQuotaLeft': data.quota.hasQuotaLeft,
      'remainingQuota': data.quota.remainingQuota,
      'isPremium': data.quota.isPremium,
      'dailyLimit': data.quota.dailyLimit,
      'standardLimit': data.quota.standardLimit,
      'premiumLimit': data.quota.premiumLimit,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await _storeSubscriptionDataInStorage(subscriptionData);

    // Store expenses if needed
    if (data.expenses.isNotEmpty) {
      await _storeExpensesInStorage(data.expenses);
    }

    // Store budget summary
    if (data.budgetSummary.budgetExists) {
      await _storeBudgetSummaryInStorage(data.budgetSummary);
    }
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

  // Store subscription data in shared preferences
  Future<void> _storeSubscriptionDataInStorage(
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscription_data', json.encode(data));
      developer.log('Subscription data stored in local storage');
    } catch (e) {
      developer.log('Error storing subscription data: $e');
    }
  }

  // Store expenses in shared preferences
  Future<void> _storeExpensesInStorage(List<Expense> expenses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expensesJson = expenses.map((e) => e.toJson()).toList();
      await prefs.setString('expenses', json.encode(expensesJson));
      developer.log('Expenses stored in local storage');
    } catch (e) {
      developer.log('Error storing expenses: $e');
    }
  }

  // Store budget summary in shared preferences
  Future<void> _storeBudgetSummaryInStorage(BudgetSummary summary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final summaryKey = 'budget_summary_${summary.year}_${summary.month}';
      final summaryData = {
        'totalBudget': summary.totalBudget,
        'totalSpending': summary.totalSpending,
        'remainingBudget': summary.remainingBudget,
        'categories':
            summary.categories
                .map(
                  (e) => {
                    'category': e.category,
                    'budget': e.budget,
                    'actual': e.actual,
                    'remaining': e.remaining,
                  },
                )
                .toList(),
        'month': summary.month,
        'year': summary.year,
        'budgetExists': summary.budgetExists,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      await prefs.setString(summaryKey, json.encode(summaryData));
      developer.log('Budget summary stored in local storage');
    } catch (e) {
      developer.log('Error storing budget summary: $e');
    }
  }

  // Prefetch and cache budget data (legacy method for fallback)
  Future<void> _prefetchBudgetData() async {
    try {
      // First check if we already have budget data in local storage
      final budgetData = await getBudgetDataFromStorage();

      // If we have valid data that's recent, skip API call
      if (budgetData != null && budgetData['success'] == true) {
        // Check if data is fresh (less than 24 hours old)
        final lastUpdated = budgetData['lastUpdated'] as String?;
        if (lastUpdated != null) {
          final lastUpdateTime = DateTime.parse(lastUpdated);
          final now = DateTime.now();
          if (now.difference(lastUpdateTime).inHours < 24) {
            developer.log('Budget data is fresh, skipping API call');
            return;
          }
        }
      }

      // Fetch from API if no valid cached data
      final apiData = await _budgetService.getUserBudget();

      // Store in local storage
      if (apiData['success'] == true) {
        // Add timestamp before storing
        apiData['lastUpdated'] = DateTime.now().toIso8601String();
        await storeBudgetDataInStorage(apiData);
        developer.log('Budget data prefetched and stored in local storage');
      }
    } catch (e) {
      developer.log('Error prefetching budget data: $e');
      // Non-critical error, don't rethrow
    }
  }

  // Prefetch and cache message quota data (legacy method for fallback)
  Future<void> _prefetchQuotaData() async {
    try {
      // First check if we have subscription data in the standard location
      final storedData = await getSubscriptionDataFromStorage();
      if (storedData != null) {
        developer.log('Using existing subscription data from storage');
        return;
      }

      // Fetch quota data from API if not available locally
      final quotaData = await _subscriptionService.getMessageQuota();

      // It's already cached in the getMessageQuota method
      developer.log('Message quota data prefetched and cached successfully');
    } catch (e) {
      developer.log('Error prefetching quota data: $e');
      // Non-critical error, don't rethrow
    }
  }

  // Helper method to get subscription data from storage (reusing homepage implementation)
  Future<Map<String, dynamic>?> getSubscriptionDataFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString("subscription_data");

      if (storedData == null || storedData.isEmpty) {
        return null;
      }

      // Parse the JSON
      final subscriptionData = jsonDecode(storedData) as Map<String, dynamic>;
      return subscriptionData;
    } catch (e) {
      developer.log("ERROR RETRIEVING SUBSCRIPTION DATA: $e");
      return null;
    }
  }

  // Clear all cached data (useful for testing or troubleshooting)
  Future<void> clearAllCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear standard app storage keys
      await prefs.remove("budget_data");
      await prefs.remove("subscription_data");
      await prefs.remove("expenses");
      await prefs.remove("app_init_data");

      // Find and remove all budget summary entries
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('budget_summary_')) {
          await prefs.remove(key);
        }
      }

      // Clear app init service cache
      await _appInitService.clearCache();

      developer.log('All cache data cleared successfully');
    } catch (e) {
      developer.log('Error clearing cache data: $e');
    }
  }

  // Reset error state
  void clearError() {
    _error = null;
  }

  // Initialize all stores with app init data
  Future<void> initializeStores(
    BudgetStore budgetStore,
    ExpenseStore expenseStore,
    ChatStore? chatStore,
  ) async {
    developer.log('Initializing all stores from app init data');

    // Check if we have cached app init data
    if (_appInitData == null) {
      developer.log('No app init data available for initializing stores');
      return;
    }

    // Initialize budget store
    budgetStore.initializeFromAppData(_appInitData!);


    // Initialize chat store if provided
    // Add chat store initialization here if needed

    developer.log('All stores initialized from app init data');
  }
}
