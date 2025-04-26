import 'package:budget_ai/api.dart';
import 'package:budget_ai/components/body_tabs.dart';
import 'package:budget_ai/components/budget_status.dart';
import 'package:budget_ai/components/leading_actions.dart';
import 'package:budget_ai/components/neumorphic_app_bar.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:budget_ai/screens/subscription_screen.dart';
import 'package:budget_ai/screens/profile_screen.dart';
import 'package:budget_ai/screens/budget_screen.dart';
import 'package:budget_ai/services/subscription_service.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:budget_ai/state/budget_store.dart';
import 'package:budget_ai/theme/index.dart';
import 'package:budget_ai/utils/time.dart';
import 'package:budget_ai/utils/money.dart';
import 'package:budget_ai/constants/config_keys.dart';
import 'package:flutter/material.dart';
import 'package:http/src/response.dart';
import 'dart:convert';
import 'dart:math';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_ai/services/app_init_service.dart';

var todayDate = DateTime.now();

List<String> months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];

// Function to store subscription data in local storage
Future<void> storeSubscriptionDataInStorage(
    {required bool isPremium,
    required int remainingQuota,
    required int dailyLimit}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> subscriptionData = {
      'isPremium': isPremium,
      'remainingQuota': remainingQuota,
      'dailyLimit': dailyLimit,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    // Convert to JSON and serialize
    final serialized = jsonEncode(subscriptionData);
    // Store in shared preferences
    await prefs.setString("subscription_data", serialized);

    developer.log('Subscription data stored in local storage');
  } catch (e) {
    developer.log("ERROR STORING SUBSCRIPTION DATA: $e");
  }
}

// Function to store config data in local storage
Future<void> storeConfigDataInStorage(Map<String, dynamic> config) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> configData = {
      'config': config,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    // Convert to JSON and serialize
    final serialized = jsonEncode(configData);
    // Store in shared preferences
    await prefs.setString("config_data", serialized);

    developer.log('Config data stored in local storage: $config');
  } catch (e) {
    developer.log("ERROR STORING CONFIG DATA: $e");
  }
}

// Function to get subscription data from local storage
Future<Map<String, dynamic>?> getSubscriptionDataFromStorage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString("subscription_data");

    if (storedData == null || storedData.isEmpty) {
      return null;
    }

    // Parse the JSON
    final subscriptionData = jsonDecode(storedData) as Map<String, dynamic>;

    developer.log('Subscription data retrieved from local storage');
    return subscriptionData;
  } catch (e) {
    developer.log("ERROR RETRIEVING SUBSCRIPTION DATA: $e");
    return null;
  }
}

// Function to get config data from local storage
Future<Map<String, dynamic>?> getConfigDataFromStorage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString("config_data");

    if (storedData == null || storedData.isEmpty) {
      return null;
    }

    // Parse the JSON
    final configData = jsonDecode(storedData) as Map<String, dynamic>;

    developer.log('Config data retrieved from local storage');
    return configData['config'] as Map<String, dynamic>;
  } catch (e) {
    developer.log("ERROR RETRIEVING CONFIG DATA: $e");
    return null;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<Expenses> futureExpenses;
  late ExpenseStore expenseStore;
  late ChatStore chatStore;
  final SubscriptionService _subscriptionService = SubscriptionService();
  final AppInitService _appInitService = AppInitService();
  bool _isSubscriptionInitialized = false;
  bool _isPremium = false;
  int _remainingMessages = 0;
  int _dailyMessageLimit = 5;

  DateTime fromDate = getMonthStart(todayDate);
  DateTime toDate = getMonthEnd(todayDate);

  Future<Expenses> fetchExpenses({bool showLoading = true}) async {
    expenseStore.loading = showLoading;

    try {
      // Use the unified app init API instead of separate API calls
      final initData = await _appInitService.fetchAppInitData(
          fromDate: fromDate,
          toDate: toDate,
          forceRefresh: showLoading // Force refresh if explicitly requested
          );

      if (initData == null) {
        expenseStore.loading = false;
        throw Exception('Failed to load app data');
      }

      // Also update the BudgetStore with data from the init response
      final budgetStore = Provider.of<BudgetStore>(context, listen: false);
      budgetStore.initializeFromAppData(initData);
      developer.log('Updated BudgetStore with data from init API response');

      // Process quota information
      final quota = initData.quota;
      final isPremium = quota.isPremium;
      final remainingQuota = quota.remainingQuota;
      final dailyLimit = quota.dailyLimit;

      // Store config data in local storage
      await storeConfigDataInStorage(initData.config);
      developer.log('Stored config data from init API in local storage');

      // Update subscription service with quota info
      await _subscriptionService.updateQuotaFromResponse(
        remainingQuota: remainingQuota,
        dailyLimit: dailyLimit,
        isPremium: isPremium,
      );

      // Store subscription data in local storage
      await storeSubscriptionDataInStorage(
        isPremium: isPremium,
        remainingQuota: remainingQuota,
        dailyLimit: dailyLimit,
      );

      // Update local state variables
      setState(() {
        _isSubscriptionInitialized = true;
        _isPremium = isPremium;
        _remainingMessages = remainingQuota;
        _dailyMessageLimit = dailyLimit;
      });

      // Convert to Expenses object and update store
      final serverExpenses = _appInitService.getExpensesFromInitData(initData);

      expenseStore.loading = false;
      expenseStore.setExpenses(serverExpenses);

      // Also update date range in expense store
      expenseStore.fromDate = initData.dateRange.fromDate;
      expenseStore.toDate = initData.dateRange.toDate;

      // Update chat with server data
      chatStore.clear();
      addChatMessages(serverExpenses);

      return serverExpenses;
    } catch (e) {
      expenseStore.loading = false;
      chatStore
          .add(TextMessage(false, "Error loading expenses: ${e.toString()}"));
      developer.log('Error in fetchExpenses: ${e.toString()}');
      rethrow;
    }
  }

  void addChatMessages(Expenses expenses) {
    if (expenses.isEmpty) {
      chatStore.add(TextMessage(true,
          "Just send a message loosely describing your expense to start your finance journey with AI."));
      return;
    }

    // First, take the 10 most recent expenses (they're already sorted newest first)
    final recentExpenses = expenses.list.take(10).toList();

    // Then reverse them so oldest appears at top and newest at bottom in the chat
    final chronologicalExpenses = recentExpenses.reversed.toList();

    // Add the expenses to the chat in chronological order
    for (var expense in chronologicalExpenses) {
      // Add the prompt if it exists
      if (expense.prompt != null && expense.prompt!.isNotEmpty) {
        chatStore.add(TextMessage(true, expense.prompt!));
      }
      // Add the expense message
      chatStore.add(ExpenseMessage(expense));
    }
  }

  Future<Object> postExpense(userMessage) async {
    bool isCurrentMonthTransaction = fromDate.month == todayDate.month;
    DateTime? date;

    if (!isCurrentMonthTransaction) {
      date = toDate;
    }

    Response response;

    try {
      response = await ApiService().addExpense(userMessage, date);
    } catch (e) {
      return Exception("Something went wrong while connecting to server");
    }

    if (response.statusCode == 200) {
      try {
        var jsonData = jsonDecode(response.body);

        // Check if response has quota information
        if (jsonData is Map<String, dynamic> && jsonData.containsKey('quota')) {
          final quota = jsonData['quota'];
          final isPremium = quota['isPremium'] as bool? ?? false;
          final remainingQuota = quota['remainingQuota'] as int? ?? 0;
          final dailyLimit = quota['dailyLimit'] as int? ?? 5;

          // Update subscription service cache with quota info
          await _subscriptionService.updateQuotaFromResponse(
              remainingQuota: remainingQuota,
              dailyLimit: dailyLimit,
              isPremium: isPremium);

          // Store subscription data in local storage
          await storeSubscriptionDataInStorage(
            isPremium: isPremium,
            remainingQuota: remainingQuota,
            dailyLimit: dailyLimit,
          );

          // Also update local state
          setState(() {
            _remainingMessages = remainingQuota;
            _dailyMessageLimit = dailyLimit;
            _isPremium = isPremium;
          });

          // Extract and return the expense
          if (jsonData.containsKey('expense')) {
            return {
              'expense': Expense.fromJson(jsonData['expense']),
              'remainingQuota': remainingQuota,
              'dailyLimit': dailyLimit,
              'isPremium': isPremium
            };
          }
        }

        // Handle legacy format or direct expense response
        if (jsonData is Map<String, dynamic> &&
            jsonData.containsKey('remainingQuota')) {
          // Old format with separate remainingQuota fields
          final remainingQuota = jsonData['remainingQuota'] as int? ?? 0;
          final dailyLimit = jsonData['dailyLimit'] as int? ?? 5;
          final isPremium = jsonData['isPremium'] as bool? ?? false;

          // Update subscription service with quota info
          await _subscriptionService.updateQuotaFromResponse(
            remainingQuota: remainingQuota,
            dailyLimit: dailyLimit,
            isPremium: isPremium,
          );

          // Store subscription data in local storage
          await storeSubscriptionDataInStorage(
            isPremium: isPremium,
            remainingQuota: remainingQuota,
            dailyLimit: dailyLimit,
          );

          // Update local state variables
          setState(() {
            _remainingMessages = remainingQuota;
            _dailyMessageLimit = dailyLimit;
            _isPremium = isPremium;
          });

          // Also extract and return the expense if it exists
          if (jsonData.containsKey('expense')) {
            return {
              'expense': Expense.fromJson(jsonData['expense']),
              'remainingQuota': remainingQuota,
              'dailyLimit': dailyLimit,
              'isPremium': isPremium
            };
          }
        }

        // Just return the expense if no quota info
        return Expense.fromJson(jsonData);
      } catch (e) {
        developer.log('Error parsing expense data: $e');
        return "Failed to parse the expense data";
      }
    } else if (response.statusCode == 403 &&
        response.body.contains('quotaExceeded')) {
      // Handle quota exceeded error
      try {
        var errorData = jsonDecode(response.body);
        if (errorData is Map<String, dynamic> &&
            errorData.containsKey('quotaExceeded') &&
            errorData['quotaExceeded'] == true) {
          // Update quota info from error response
          if (errorData.containsKey('quota')) {
            final quota = errorData['quota'];
            final remainingQuota = quota['remainingQuota'] as int? ?? 0;
            final dailyLimit = quota['dailyLimit'] as int? ?? 5;
            final isPremium = quota['isPremium'] as bool? ?? false;

            await _subscriptionService.updateQuotaFromResponse(
                remainingQuota: remainingQuota,
                dailyLimit: dailyLimit,
                isPremium: isPremium);

            // Store subscription data in local storage
            await storeSubscriptionDataInStorage(
              isPremium: isPremium,
              remainingQuota: remainingQuota,
              dailyLimit: dailyLimit,
            );

            // Also update local state
            setState(() {
              _remainingMessages = remainingQuota;
              _dailyMessageLimit = dailyLimit;
              _isPremium = isPremium;
            });
          } else if (errorData.containsKey('remainingQuota') &&
              errorData.containsKey('dailyLimit')) {
            // Legacy format with fields at top level
            final remainingQuota = errorData['remainingQuota'] as int? ?? 0;
            final dailyLimit = errorData['dailyLimit'] as int? ?? 5;
            final isPremium = errorData['isPremium'] as bool? ?? false;

            await _subscriptionService.updateQuotaFromResponse(
                remainingQuota: remainingQuota,
                dailyLimit: dailyLimit,
                isPremium: isPremium);

            // Store subscription data in local storage
            await storeSubscriptionDataInStorage(
              isPremium: isPremium,
              remainingQuota: remainingQuota,
              dailyLimit: dailyLimit,
            );

            // Also update local state
            setState(() {
              _remainingMessages = remainingQuota;
              _dailyMessageLimit = dailyLimit;
              _isPremium = isPremium;
            });
          }
          return errorData['errorMessage'] ?? "Daily message quota exceeded";
        }
      } catch (e) {
        developer.log('Error parsing quota error: $e');
      }
      return "You've reached your daily limit of AI messages";
    } else if (response.statusCode == 401) {
      var errorMsg = jsonDecode(response.body)["errorMessage"] ??
          "Something went wrong while adding";
      return errorMsg;
    } else {
      throw Exception('Failed to add expense');
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize expenses and chatStore
    expenseStore = Provider.of<ExpenseStore>(context, listen: false);
    chatStore = Provider.of<ChatStore>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // First load expenses from local storage
      Expenses localExpenses = await getExpensesFromStorage();

      // Set the expenses in the store immediately and add to chat
      expenseStore.setExpenses(localExpenses);
      expenseStore.loading =
          false; // Set loading to false after setting local expenses

      // Try to get subscription data from local storage
      final localSubscriptionData = await getSubscriptionDataFromStorage();
      if (localSubscriptionData != null) {
        // Use stored subscription data if available
        setState(() {
          _isSubscriptionInitialized = true;
          _isPremium = localSubscriptionData['isPremium'] ?? false;
          _remainingMessages = localSubscriptionData['remainingQuota'] ?? 0;
          _dailyMessageLimit = localSubscriptionData['dailyLimit'] ?? 5;
        });
        developer.log('Using subscription data from local storage');
      }

      // Add local expenses to chat immediately
      if (!localExpenses.isEmpty) {
        addChatMessages(localExpenses);
      }

      // Now call the unified init API to get all updated data
      try {
        developer.log('Calling unified init API to get fresh data...');

        // Call the refresh expenses function which uses the init API
        final updatedExpenses = await refreshExpenses(showLoading: true);
        developer.log(
            'Successfully retrieved ${updatedExpenses.list.length} expenses from init API');

        // The budget store will be automatically updated with the data from init API
        // in the fetchExpenses method via the initializeFromAppData flow
      } catch (e) {
        developer.log('Error fetching data from init API: $e');

        // Fallback to separate API calls if needed
        try {
          // Prepare all API calls
          final budgetStore = Provider.of<BudgetStore>(context, listen: false);

          // Get budget data
          await budgetStore.initializeBudget().catchError((e) {
            developer.log('Error fetching budget config: $e');
            return null; // Just continue if budget config fails
          });

          developer.log('Fallback API calls completed');
        } catch (secondaryError) {
          developer.log('All API fallback attempts failed: $secondaryError');
        }

        // If no subscription data was loaded from local storage, initialize it locally
        if (localSubscriptionData == null) {
          await _initializeSubscriptionLocally();
        }
      }
    });
  }

  // Initialize subscription locally as fallback
  Future<void> _initializeSubscriptionLocally() async {
    // Try to get data from local storage first
    final localData = await getSubscriptionDataFromStorage();

    if (localData != null) {
      // Use stored data if available
      setState(() {
        _isSubscriptionInitialized = true;
        _isPremium = localData['isPremium'] ?? false;
        _remainingMessages = localData['remainingQuota'] ?? 0;
        _dailyMessageLimit = localData['dailyLimit'] ?? 5;
      });
      developer.log('Using subscription data from local storage');
      return;
    }

    // Fall back to subscription service if no local data
    await _subscriptionService.initializeSubscriptions();
    final isPremium = await _subscriptionService.isPremium();
    final remainingMessages =
        await _subscriptionService.getRemainingMessageCount() ?? 0;
    final dailyLimit = await _subscriptionService.getDailyMessageLimit();

    setState(() {
      _isSubscriptionInitialized = true;
      _isPremium = isPremium;
      _remainingMessages = remainingMessages;
      _dailyMessageLimit = dailyLimit;
    });

    // Store this data for future offline access
    await storeSubscriptionDataInStorage(
      isPremium: isPremium,
      remainingQuota: remainingMessages,
      dailyLimit: dailyLimit,
    );
  }

  Future<Expenses> getExpensesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString("expenses");

      if (storedData == null || storedData.isEmpty) {
        return Expenses(List.empty());
      }

      // Parse the JSON
      final storedExpenses = jsonDecode(storedData);

      // Create Expenses object
      var expenses = Expenses.fromJson(storedExpenses);

      // Sort expenses by datetime to ensure newest first
      expenses.list.sort((a, b) => b.datetime.compareTo(a.datetime));

      // Log a sample of the loaded expenses
      final sampleExpenses = expenses.list
          .take(min(3, expenses.list.length))
          .map((e) =>
              "ID: ${e.id}, Amount: ${e.amount}, Category: ${e.category}")
          .join("\n");

      return expenses;
    } catch (e) {
      // Return empty list on error
      return Expenses(List.empty());
    }
  }

  Future<Expenses> refreshExpenses({bool showLoading = true}) async {
    if (showLoading) {
      expenseStore.loading = true;
    }

    try {
      futureExpenses = fetchExpenses(showLoading: showLoading);
      return await futureExpenses;
    } catch (e) {
      developer.log('Error in refreshExpenses: ${e.toString()}');
      // Return the current expenses if the refresh fails
      return expenseStore.expenses;
    } finally {
      // Make sure loading state is cleared even if an error occurs
      if (expenseStore.loading) {
        expenseStore.loading = false;
      }
    }
  }

  Future<void> updateTimeFrame(newFromDate, newToDate) async {
    setState(() {
      fromDate = newFromDate;
      toDate = newToDate;
    });
    refreshExpenses();
  }

  Future<Expense?> addExpense(dynamic userInput) async {
    // If input is already an Expense object (from manual creation)
    if (userInput is Expense) {
      try {
        // Add the expense to the chat and store
        chatStore.add(ExpenseMessage(userInput));
        expenseStore.add(userInput, context: context);
        storeExpensesInStorage(expenseStore.expenses);
        // Notify for scroll update
        chatStore.notifyScrollUpdate();

        return userInput;
      } catch (e) {
        chatStore.add(TextMessage(false, "Error adding manual expense: $e"));
        return null;
      }
    }

    // Otherwise, treat as a message for AI processing
    String userMessage = userInput as String;

    if (userMessage == "") {
      chatStore.add(TextMessage(
          false, "Please send a message with details to add expense"));
      return null;
    }

    // Check if user can send message
    bool canSend = await _subscriptionService.canSendMessage();
    if (!canSend) {
      chatStore.add(TextMessage(false,
          "You've reached your daily message limit. Upgrade to premium for unlimited messages."));
      return null;
    }

    try {
      chatStore.add(TextMessage(true, userMessage));
      chatStore.add(AILoading());
      var result = await postExpense(userMessage);
      chatStore.pop();

      if (result is Expense) {
        // Add the expense to the UI first
        chatStore.add(ExpenseMessage(result));
        // Pass the context to update the budget
        expenseStore.add(result, context: context);
        storeExpensesInStorage(expenseStore.expenses);
        // Notify for scroll update
        chatStore.notifyScrollUpdate();

        return result;
      } else if (result is Map<String, dynamic> &&
          result.containsKey('expense')) {
        // This handles the case where we have both an expense and quota info
        final expense = result['expense'] as Expense;

        // Add the expense to the UI
        chatStore.add(ExpenseMessage(expense));
        // Pass the context to update the budget
        expenseStore.add(expense, context: context);
        storeExpensesInStorage(expenseStore.expenses);
        // Notify for scroll update
        chatStore.notifyScrollUpdate();

        return expense;
      }

      // If we get here, the expense wasn't successfully created
      chatStore.add(TextMessage(false, result.toString()));
      // Notify for scroll update
      chatStore.notifyScrollUpdate();
      return null;
    } catch (e) {
      developer.log(
        'Error creating expense: ${e.toString()}',
      );
      chatStore.pop();
      chatStore.add(TextMessage(
          false, "Something went wrong while trying to connect to Finget"));
      // Notify for scroll update
      chatStore.notifyScrollUpdate();
      return null;
    }
  }

  void _showSubscriptionDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
    );
  }

  Future<void> clearLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("expenses");
      await prefs.remove("subscription_data");
      await prefs.remove("config_data"); // Also clear config data

      // Clear the app init service cache
      await _appInitService.clearCache();

      // Reset the expense store
      expenseStore.setExpenses(Expenses(List.empty()));

      // Also reset subscription state
      setState(() {
        _isPremium = false;
        _remainingMessages = 0;
        _dailyMessageLimit = 5;
      });

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local storage cleared')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing local storage: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    expenseStore = Provider.of<ExpenseStore>(context, listen: true);
    chatStore = Provider.of<ChatStore>(context, listen: true);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? NeumorphicColors.darkPrimaryBackground
        : NeumorphicColors.lightPrimaryBackground;

    return Scaffold(
      appBar: NeumorphicAppBar(
        title: widget.title,
        useAccentColor: true, // Use the blue background
        showShadow: false, // No shadow for clean look
        elevation: 0,
        leading: LeadingActions(fromDate, toDate,
            updateTimeFrame), // Month selector back in app bar
        actions: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark
                ? NeumorphicColors.darkAccent.withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
            child: IconButton(
              icon: Icon(
                Icons.diamond_outlined,
                color: isDark ? NeumorphicColors.darkAccent : Colors.white,
                size: 18,
              ),
              onPressed: _showSubscriptionDialog,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark
                ? NeumorphicColors.darkAccent.withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
            child: IconButton(
              icon: Icon(
                Icons.person,
                color: isDark ? NeumorphicColors.darkAccent : Colors.white,
                size: 18,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomProfileScreen(),
                  ),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        color: backgroundColor,
        child: Stack(
          children: [
            // Show content even when loading, just add loading indicator on top
            Column(
              children: [
                // Unified budget card combining both date selection and budget info
                Consumer<BudgetStore>(
                  builder: (context, budgetStore, _) {
                    // Calculate budget percentage
                    double percentUsed = 0.0;
                    double remaining = 0.0;
                    double total = expenseStore.expenses.total;

                    if (budgetStore.budgetSummary != null) {
                      // Use the data from the budget summary if available
                      percentUsed = budgetStore.budgetSummary!.totalBudget > 0
                          ? (budgetStore.budgetSummary!.totalSpending /
                                  budgetStore.budgetSummary!.totalBudget)
                              .clamp(0.0, 1.0)
                          : 0.0;
                      remaining = budgetStore.budgetSummary!.remainingBudget;
                    } else if (budgetStore.budget.total > 0) {
                      // Fall back to the budget configuration if summary is not available
                      percentUsed =
                          (total / budgetStore.budget.total).clamp(0.0, 1.0);
                      remaining = budgetStore.budget.total - total;
                    }

                    final percentDisplay =
                        "${(percentUsed * 100).toStringAsFixed(0)}%";

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 16.0),
                      decoration: NeumorphicBox.decoration(
                        context: context,
                        color: isDark
                            ? NeumorphicColors.darkCardBackground
                            : NeumorphicColors.lightCardBackground,
                        borderRadius: 16.0,
                        depth: 8.0, // Increased depth for more prominent shadow
                        intensity: 0.9, // Higher intensity shadow
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              (isDark
                                      ? NeumorphicColors.darkCardBackground
                                      : NeumorphicColors.lightCardBackground)
                                  .withOpacity(1.0),
                              (isDark
                                  ? NeumorphicColors.darkCardBackground
                                      .withOpacity(0.9)
                                  : NeumorphicColors.lightCardBackground
                                      .withOpacity(0.92)),
                            ],
                          ),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03),
                            width: 0.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Budget month and year with edit button
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    fromDate.year == todayDate.year
                                        ? '${monthFormat.format(fromDate)} month'
                                        : '${monthAndYearFormat.format(fromDate)} month',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? NeumorphicColors.darkTextSecondary
                                          : NeumorphicColors.lightTextSecondary,
                                    ),
                                  ),

                                  // Edit budget button
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const BudgetScreen()),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.black.withOpacity(0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: isDark
                                            ? NeumorphicColors.darkTextSecondary
                                            : NeumorphicColors
                                                .lightTextSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Total spent this month
                              Text(
                                currencyFormat.format(total),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? NeumorphicColors.darkTextPrimary
                                      : NeumorphicColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Budget info
                              Text(
                                "Monthly Budget",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? NeumorphicColors.darkTextSecondary
                                      : NeumorphicColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Progress bar row
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: isDark
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.black.withOpacity(0.05),
                                      ),
                                      child: FractionallySizedBox(
                                        widthFactor: percentUsed,
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            gradient: LinearGradient(
                                              colors: [
                                                isDark
                                                    ? NeumorphicColors
                                                        .darkAccent
                                                    : NeumorphicColors
                                                        .lightAccent,
                                                isDark
                                                    ? NeumorphicColors
                                                        .darkSecondaryAccent
                                                    : NeumorphicColors
                                                        .lightSecondaryAccent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    percentDisplay,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? NeumorphicColors.darkTextPrimary
                                          : NeumorphicColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Remaining amount
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Remaining",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? NeumorphicColors.darkTextPrimary
                                          : NeumorphicColors.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(remaining),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: remaining < 0
                                          ? Colors.red
                                          : isDark
                                              ? NeumorphicColors.darkAccent
                                              : NeumorphicColors.lightAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Tabs section
                Expanded(
                  child: BodyTabs(
                    addExpense,
                    quotaData: {
                      'remainingMessages': _remainingMessages,
                      'dailyLimit': _dailyMessageLimit,
                      'isPremium': _isPremium,
                    },
                  ),
                ),
              ],
            ),
            // Show loading indicator as overlay
            if (expenseStore.loading)
              Container(
                color: backgroundColor.withOpacity(0.7),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: backgroundColor,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: const SizedBox(height: 0),
      ),
    );
  }
}
