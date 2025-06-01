import 'package:coin_master_ai/models/budget.dart';
import 'package:coin_master_ai/services/budget_service.dart';
import 'package:coin_master_ai/models/app_init_response.dart' as init_api;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;

// Store budget data in local storage
Future<void> storeBudgetDataInStorage(Map<String, dynamic> budgetData) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(budgetData);

    // Store in shared preferences
    await prefs.setString("budget_data", jsonString);

    developer.log('Budget data stored in local storage');
  } catch (e) {
    developer.log("ERROR STORING BUDGET DATA: $e");
  }
}

// Get budget data from local storage
Future<Map<String, dynamic>?> getBudgetDataFromStorage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString("budget_data");

    if (storedData == null || storedData.isEmpty) {
      return null;
    }

    // Parse the JSON
    final budgetData = jsonDecode(storedData) as Map<String, dynamic>;

    developer.log('Budget data retrieved from local storage');
    return budgetData;
  } catch (e) {
    developer.log("ERROR RETRIEVING BUDGET DATA: $e");
    return null;
  }
}

// Store budget summary in local storage
Future<void> storeBudgetSummaryInStorage(
  Map<String, dynamic> summaryData, {
  int? month,
  int? year,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(summaryData);

    // Create a key with month and year
    final key = _createSummaryKey(month, year);

    // Store in shared preferences
    await prefs.setString(key, jsonString);

    developer.log('Budget summary stored in local storage for $key');
  } catch (e) {
    developer.log("ERROR STORING BUDGET SUMMARY: $e");
  }
}

// Get budget summary from local storage
Future<Map<String, dynamic>?> getBudgetSummaryFromStorage({
  int? month,
  int? year,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final key = _createSummaryKey(month, year);
    final storedData = prefs.getString(key);

    if (storedData == null || storedData.isEmpty) {
      return null;
    }

    // Parse the JSON
    final summaryData = jsonDecode(storedData) as Map<String, dynamic>;

    developer.log('Budget summary retrieved from local storage for $key');
    return summaryData;
  } catch (e) {
    developer.log("ERROR RETRIEVING BUDGET SUMMARY: $e");
    return null;
  }
}

// Create a key for storing budget summary
String _createSummaryKey(int? month, int? year) {
  if (month != null && year != null) {
    return 'budget_summary_${month}_$year';
  }

  // Use current month and year if not provided
  final now = DateTime.now();
  return 'budget_summary_${now.month}_${now.year}';
}

class BudgetStore with ChangeNotifier {
  // Budget service for API calls
  final BudgetService _budgetService = BudgetService();

  // Budget data
  Budget _budget = Budget();
  BudgetSummary? _budgetSummary;
  List<String> _categories = budgetList;

  // Loading states
  bool _loading = false;
  String? _error;
  bool _hasCachedData = false;

  // Getters
  Budget get budget => _budget;
  BudgetSummary? get budgetSummary => _budgetSummary;
  List<String> get categories => _categories;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasCachedData => _hasCachedData;

  // Initialize from app init response
  void initializeFromAppData(init_api.AppInitResponse initData) {
    developer.log(
      "\n------- INITIALIZING BUDGET STORE FROM APP INIT DATA -------",
    );

    try {
      // Update budget
      if (initData.budget.budgetExists && initData.budget.budget != null) {
        _budget = initData.budget.budget!;
        developer.log(
          "Budget initialized from app init data, ID: ${_budget.id}",
        );
      }

      // Update categories
      _categories = initData.budget.categories;
      developer.log(
        "Categories updated from app init data: ${_categories.join(', ')}",
      );

      // Update budget summary
      if (initData.budgetSummary.budgetExists) {
        final initSummary = initData.budgetSummary;

        // Convert category summaries from API format to app format
        final categoryData =
            initSummary.categories
                .map(
                  (cat) => CategorySummary(
                    category: cat.category,
                    budget: cat.budget,
                    actual: cat.actual,
                    remaining: cat.remaining,
                  ),
                )
                .toList();

        // Create BudgetSummary instance from our models
        _budgetSummary = BudgetSummary(
          totalBudget: initSummary.totalBudget,
          totalSpending: initSummary.totalSpending,
          remainingBudget: initSummary.remainingBudget,
          categories: categoryData,
          month: initSummary.month,
          year: initSummary.year,
        );

        developer.log("Budget summary initialized from app init data");
      }

      _hasCachedData = true;
      developer.log("------- BUDGET STORE INITIALIZATION COMPLETE -------\n");
      notifyListeners();
    } catch (e) {
      _error = 'Error initializing from app data: $e';
      developer.log(_error!);
    }
  }

  // Initialize the budget store by fetching data from local storage first, then API
  Future<void> initializeBudget() async {
    _loading = true;
    notifyListeners();

    try {
      // First try to load from local storage
      await _loadFromLocalStorage();

      // Then fetch fresh data from API
      await _fetchFromAPI();
    } catch (e) {
      _error = 'Error initializing budget: $e';
      developer.log(_error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Initialize budget from local storage only (no API calls)
  Future<void> initializeBudgetFromLocalStorage() async {
    _loading = true;
    notifyListeners();

    try {
      // Only load from local storage
      await _loadFromLocalStorage();

      // Set the flag if we have data
      if (_budget.id != null) {
        _hasCachedData = true;
      }
    } catch (e) {
      _error = 'Error loading budget from local storage: $e';
      developer.log(_error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Load budget data from local storage
  Future<void> _loadFromLocalStorage() async {
    try {
      final cachedBudget = await getBudgetDataFromStorage();

      if (cachedBudget != null &&
          cachedBudget['success'] == true &&
          cachedBudget['budget'] != null) {
        _budget = Budget.fromJson(cachedBudget['budget']);

        // Store categories if provided
        if (cachedBudget['categories'] != null) {
          _categories = List<String>.from(cachedBudget['categories']);
        }

        _hasCachedData = true;
        developer.log('Budget loaded from local storage successfully');

        // Notify listeners of the update
        notifyListeners();
      }
    } catch (e) {
      developer.log('Error loading budget from local storage: $e');
    }
  }

  // Fetch budget data from API and store in local storage
  Future<void> _fetchFromAPI() async {
    try {
      // Get user budget configuration
      final budgetData = await _budgetService.getUserBudget();

      if (budgetData['success'] == true && budgetData['budget'] != null) {
        // Parse and store budget data
        _budget = Budget.fromJson(budgetData['budget']);

        // Store categories if provided by API
        if (budgetData['categories'] != null) {
          _categories = List<String>.from(budgetData['categories']);
        }

        // Store the API response in local storage
        await storeBudgetDataInStorage(budgetData);

        _hasCachedData = true;
        developer.log(
          'Budget data updated from API and stored in local storage',
        );

        // Clear any previous errors
        _error = null;
      } else {
        _error = budgetData['errorMessage'] ?? 'Failed to load budget data';
      }
    } catch (e) {
      _error = 'Error loading budget from API: $e';
      developer.log(_error!);
    }
  }

  // Fetch budget summary for a specific month
  Future<void> fetchBudgetSummary({int? month, int? year}) async {
    _loading = true;
    notifyListeners();

    try {
      // First check if summary is in local storage
      final cachedSummary = await getBudgetSummaryFromStorage(
        month: month,
        year: year,
      );

      if (cachedSummary != null && cachedSummary['success'] == true) {
        _budgetSummary = BudgetSummary.fromJson(cachedSummary);
        developer.log('Budget summary loaded from local storage');
      }

      // Fetch fresh data from API
      final summaryData = await _budgetService.getBudgetSummary(
        month: month,
        year: year,
      );

      if (summaryData['success'] == true) {
        _budgetSummary = BudgetSummary.fromJson(summaryData);

        // Store the API response in local storage
        await storeBudgetSummaryInStorage(
          summaryData,
          month: month,
          year: year,
        );

        _error = null;
      } else {
        // If API fails but we have cached data, keep using it
        if (_budgetSummary == null) {
          _error =
              summaryData['errorMessage'] ?? 'Failed to load budget summary';
        }
      }
    } catch (e) {
      _error = 'Error loading budget summary: $e';
      developer.log(_error!);

      // Try loading from cache if API fails
      if (_budgetSummary == null) {
        try {
          final cachedSummary = await getBudgetSummaryFromStorage(
            month: month,
            year: year,
          );

          if (cachedSummary != null && cachedSummary['success'] == true) {
            _budgetSummary = BudgetSummary.fromJson(cachedSummary);
            developer.log(
              'Budget summary loaded from local storage after API failure',
            );
          }
        } catch (cacheError) {
          developer.log(
            'Failed to load summary from local storage: $cacheError',
          );
        }
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Set total budget
  Future<void> setTotalBudget(double amount) async {
    _loading = true;
    notifyListeners();

    try {
      final response = await _budgetService.setTotalBudget(amount);

      if (response['success'] == true && response['budget'] != null) {
        _budget = Budget.fromJson(response['budget']);

        // Update local storage with new data
        await storeBudgetDataInStorage({
          'success': true,
          'budget': response['budget'],
          'categories': _categories,
        });

        _error = null;
      } else {
        _error = response['errorMessage'] ?? 'Failed to update total budget';
      }
    } catch (e) {
      _error = 'Error updating total budget: $e';
      developer.log(_error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Set category budget with optimistic update
  Future<void> setCategoryBudgetOptimistic(
    String category,
    double amount,
  ) async {
    // First update the budget in memory for immediate UI feedback
    final updatedBudget = Budget(
      id: _budget.id,
      totalBudget: _budget.totalBudget,
      categoryBudgets: Map.from(_budget.categoryBudgets),
    );

    // Store the old amount for potential summary updates
    final oldAmount = updatedBudget.categoryBudgets[category] ?? 0.0;

    updatedBudget.updateAmount(category, amount);
    _budget = updatedBudget;

    // Update budget summary if it exists for the current month
    if (_budgetSummary != null) {
      _updateSummaryForCategoryBudgetChange(category, oldAmount, amount);
    }

    // Notify listeners for immediate UI update
    notifyListeners();

    // Then perform the API call
    try {
      final response = await _budgetService.setCategoryBudget(category, amount);

      if (response['success'] == true && response['budget'] != null) {
        // Update again with server response
        _budget = Budget.fromJson(response['budget']);

        // Update local storage with new data
        await storeBudgetDataInStorage({
          'success': true,
          'budget': response['budget'],
          'categories': _categories,
        });

        _error = null;
      } else {
        _error = response['errorMessage'] ?? 'Failed to update category budget';

        // In case of error, notify the UI
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error updating category budget: $e';
      developer.log(_error!);

      // In case of error, notify the UI
      notifyListeners();
    }
  }

  // Helper method to update budget summary when a category budget changes
  void _updateSummaryForCategoryBudgetChange(
    String category,
    double oldAmount,
    double newAmount,
  ) {
    // Skip if we don't have a budget summary
    if (_budgetSummary == null) return;

    // Create updated category list
    List<CategorySummary> updatedCategories =
        _budgetSummary!.categories.map((cat) {
          // If this is the affected category, update it
          if (cat.category.toLowerCase() == category.toLowerCase()) {
            // Calculate new remaining amount based on the updated budget
            double newRemaining = newAmount - cat.actual;

            // Return updated category
            return CategorySummary(
              category: cat.category,
              budget: newAmount,
              actual: cat.actual,
              remaining: newRemaining,
            );
          }

          // Return unchanged category
          return cat;
        }).toList();

    // Check if we need to add a new category that wasn't in the summary
    bool categoryExists = updatedCategories.any(
      (cat) => cat.category.toLowerCase() == category.toLowerCase(),
    );

    if (!categoryExists) {
      // Add new category to the summary with 0 actual spending
      updatedCategories.add(
        CategorySummary(
          category: category,
          budget: newAmount,
          actual: 0,
          remaining: newAmount,
        ),
      );
    }

    // Calculate the change in total budget (could be positive or negative)
    double budgetChange = newAmount - oldAmount;
    double newTotalBudget = _budgetSummary!.totalBudget + budgetChange;

    // Recalculate remaining budget with the updated total budget
    double newRemainingBudget = newTotalBudget - _budgetSummary!.totalSpending;

    // Create new budget summary
    _budgetSummary = BudgetSummary(
      totalBudget: newTotalBudget,
      totalSpending: _budgetSummary!.totalSpending,
      remainingBudget: newRemainingBudget,
      categories: updatedCategories,
      month: _budgetSummary!.month,
      year: _budgetSummary!.year,
      id: _budgetSummary!.id,
    );

    // Update local storage with the modified summary
    storeBudgetSummaryInStorage(
      {
        'success': true,
        'summary': {
          'totalBudget': _budgetSummary!.totalBudget,
          'totalSpending': _budgetSummary!.totalSpending,
          'remainingBudget': _budgetSummary!.remainingBudget,
          'month': _budgetSummary!.month,
          'year': _budgetSummary!.year,
          '_id': _budgetSummary!.id,
          'categories':
              _budgetSummary!.categories
                  .map(
                    (cat) => {
                      'category': cat.category,
                      'budget': cat.budget,
                      'actual': cat.actual,
                      'remaining': cat.remaining,
                    },
                  )
                  .toList(),
        },
      },
      month: _budgetSummary!.month,
      year: _budgetSummary!.year,
    );
  }

  // Set category budget (original method)
  Future<void> setCategoryBudget(String category, double amount) async {
    _loading = true;
    notifyListeners();

    // Store the old amount for potential summary updates
    final oldAmount = _budget.categoryBudgets[category] ?? 0.0;

    try {
      final response = await _budgetService.setCategoryBudget(category, amount);

      if (response['success'] == true && response['budget'] != null) {
        _budget = Budget.fromJson(response['budget']);

        // Update budget summary if it exists for the current month
        if (_budgetSummary != null) {
          _updateSummaryForCategoryBudgetChange(category, oldAmount, amount);
        }

        // Update local storage with new data
        await storeBudgetDataInStorage({
          'success': true,
          'budget': response['budget'],
          'categories': _categories,
        });

        _error = null;
      } else {
        _error = response['errorMessage'] ?? 'Failed to update category budget';
      }
    } catch (e) {
      _error = 'Error updating category budget: $e';
      developer.log(_error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Set multiple category budgets
  Future<void> setMultipleCategoryBudgets(
    Map<String, double> categoryBudgets,
  ) async {
    _loading = true;
    notifyListeners();

    // Store the old budget for comparison and summary updates
    final oldBudget = Map<String, double>.from(_budget.categoryBudgets);

    try {
      final response = await _budgetService.setMultipleCategoryBudgets(
        categoryBudgets,
      );

      if (response['success'] == true && response['budget'] != null) {
        _budget = Budget.fromJson(response['budget']);

        // Update budget summary if it exists
        if (_budgetSummary != null) {
          // Process each changed, added, or removed category
          final Set<String> allCategories = {
            ...oldBudget.keys,
            ...categoryBudgets.keys,
          };

          for (final category in allCategories) {
            final oldAmount = oldBudget[category] ?? 0.0;
            final newAmount = categoryBudgets[category] ?? 0.0;

            // Only update if there's a change
            if (oldAmount != newAmount) {
              _updateSummaryForCategoryBudgetChange(
                category,
                oldAmount,
                newAmount,
              );
            }
          }
        }

        // Update local storage with new data
        await storeBudgetDataInStorage({
          'success': true,
          'budget': response['budget'],
          'categories': _categories,
        });

        _error = null;
      } else {
        _error =
            response['errorMessage'] ??
            'Failed to update multiple category budgets';
      }
    } catch (e) {
      _error = 'Error updating multiple category budgets: $e';
      developer.log(_error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Delete budget
  Future<void> deleteBudget() async {
    _loading = true;
    notifyListeners();

    try {
      final response = await _budgetService.deleteBudget();

      if (response['success'] == true) {
        // Reset to default budget
        _budget = Budget();
        _budgetSummary = null;

        // Clear cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove("budget_data");

        // Find and remove all summary cache entries
        final keys = prefs.getKeys();
        for (final key in keys) {
          if (key.startsWith('budget_summary_')) {
            await prefs.remove(key);
          }
        }

        _hasCachedData = false;
        _error = null;
      } else {
        _error = response['errorMessage'] ?? 'Failed to delete budget';
      }
    } catch (e) {
      _error = 'Error deleting budget: $e';
      developer.log(_error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Force refresh budget data from API
  Future<void> refreshBudgetData() async {
    _loading = true;
    notifyListeners();

    try {
      // Fetch fresh data from API
      await _fetchFromAPI();

      // Also refresh summary if we have it
      if (_budgetSummary != null) {
        await fetchBudgetSummary(
          month: _budgetSummary!.month,
          year: _budgetSummary!.year,
        );
      }
    } catch (e) {
      _error = 'Error refreshing budget data: $e';
      developer.log(_error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Reset error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Update budget summary when expenses are added, edited, or deleted
  void updateBudgetForExpenseChange(
    num expenseAmount,
    String category, {
    bool isAddition = true,
    bool isUpdate = false,
    num? oldAmount,
  }) {
    if (_budgetSummary == null) return;

    // Convert num to double to avoid type issues
    final double expenseAmountDouble = expenseAmount.toDouble();
    final double? oldAmountDouble = oldAmount?.toDouble();

    // Calculate new values
    double newTotalSpending = _budgetSummary!.totalSpending;

    // If this is an update, we need to remove the old amount first
    if (isUpdate && oldAmountDouble != null) {
      newTotalSpending -= oldAmountDouble;
    }

    // Now apply the new expense amount
    if (isAddition) {
      newTotalSpending += expenseAmountDouble;
    } else {
      newTotalSpending -= expenseAmountDouble;
    }

    // Calculate new remaining budget
    double newRemainingBudget = _budgetSummary!.totalBudget - newTotalSpending;

    // Create updated category list
    List<CategorySummary> updatedCategories =
        _budgetSummary!.categories.map((cat) {
          // If this is the affected category, update it
          if (cat.category.toLowerCase() == category.toLowerCase()) {
            double newActual = cat.actual;

            // Handle update case first (remove old amount)
            if (isUpdate && oldAmountDouble != null) {
              newActual -= oldAmountDouble;
            }

            // Apply the new amount
            if (isAddition) {
              newActual += expenseAmountDouble;
            } else {
              newActual -= expenseAmountDouble;
            }

            // Calculate new remaining amount
            double newRemaining = cat.budget - newActual;

            // Return updated category
            return CategorySummary(
              category: cat.category,
              budget: cat.budget,
              actual: newActual,
              remaining: newRemaining,
            );
          }

          // Return unchanged category
          return cat;
        }).toList();

    // Create new budget summary
    _budgetSummary = BudgetSummary(
      totalBudget: _budgetSummary!.totalBudget,
      totalSpending: newTotalSpending,
      remainingBudget: newRemainingBudget,
      categories: updatedCategories,
      month: _budgetSummary!.month,
      year: _budgetSummary!.year,
      id: _budgetSummary!.id,
    );

    // Update local storage with the modified summary
    storeBudgetSummaryInStorage(
      {
        'success': true,
        'summary': {
          'totalBudget': _budgetSummary!.totalBudget,
          'totalSpending': _budgetSummary!.totalSpending,
          'remainingBudget': _budgetSummary!.remainingBudget,
          'month': _budgetSummary!.month,
          'year': _budgetSummary!.year,
          '_id': _budgetSummary!.id,
          'categories':
              _budgetSummary!.categories
                  .map(
                    (cat) => {
                      'category': cat.category,
                      'budget': cat.budget,
                      'actual': cat.actual,
                      'remaining': cat.remaining,
                    },
                  )
                  .toList(),
        },
      },
      month: _budgetSummary!.month,
      year: _budgetSummary!.year,
    );

    // Notify listeners about the changes
    notifyListeners();
  }
}
