import 'package:budget_ai/api.dart';
import 'package:budget_ai/components/body_tabs.dart';
import 'package:budget_ai/components/budget_status.dart';
import 'package:budget_ai/components/leading_actions.dart';
import 'package:budget_ai/components/neumorphic_app_bar.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:budget_ai/screens/subscription_screen.dart';
import 'package:budget_ai/screens/profile_screen.dart';
import 'package:budget_ai/services/subscription_service.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:budget_ai/theme/index.dart';
import 'package:budget_ai/utils/time.dart';
import 'package:budget_ai/utils/money.dart';
import 'package:flutter/material.dart';
import 'package:http/src/response.dart';
import 'dart:convert';
import 'dart:math';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isSubscriptionInitialized = false;
  bool _isPremium = false;
  int _remainingMessages = 0;
  int _dailyMessageLimit = 5;

  DateTime fromDate = getMonthStart(todayDate);
  DateTime toDate = getMonthEnd(todayDate);

  Future<Expenses> fetchExpenses({bool showLoading = true}) async {
    expenseStore.loading = showLoading;
    var response;

    try {
      print("\n------- FETCH EXPENSES FROM SERVER -------");
      print(
          "Current local expense count: ${expenseStore.expenses.list.length}");
      print("Current chat message count: ${chatStore.history.messages.length}");
      print(
          "Fetching expenses from server for ${fromDate.toIso8601String()} to ${toDate.toIso8601String()}");
      response = await ApiService().fetchExpenses(fromDate, toDate);
      print("Fetch response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        try {
          var jsonData = jsonDecode(response.body) as List<dynamic>;
          print("\nServer Response Analysis:");
          print("Server returned ${jsonData.length} expenses");

          // Parse server expenses
          var serverExpenses = Expenses.fromJson(jsonData);
          expenseStore.loading = false;

          // Log expense IDs and details for debugging
          print("\nServer Expenses Details:");
          for (var expense in serverExpenses.list.take(5)) {
            print(
                "ID: ${expense.id}, Amount: ${expense.amount}, Date: ${expense.datetime}, Category: ${expense.category}, Description: ${expense.description}");
          }
          if (serverExpenses.list.length > 5) {
            print("... and ${serverExpenses.list.length - 5} more expenses");
          }

          // Create a function to compare expenses
          bool expensesMatch(Expense a, Expense b) {
            return a.amount == b.amount &&
                a.category == b.category &&
                a.description == b.description &&
                a.datetime.difference(b.datetime).inSeconds.abs() <
                    2; // Allow 2 second difference
          }

          // Find expenses in local store that don't exist on server
          final localExpenses = expenseStore.expenses.list;
          print("\nLocal Store Analysis:");
          print("Local store has ${localExpenses.length} expenses");

          // Log local expense details for debugging
          print("\nLocal Expenses Details:");
          for (var expense in localExpenses.take(5)) {
            print(
                "ID: ${expense.id}, Amount: ${expense.amount}, Date: ${expense.datetime}, Category: ${expense.category}, Description: ${expense.description}");
          }
          if (localExpenses.length > 5) {
            print("... and ${localExpenses.length - 5} more expenses");
          }

          // Find truly unique local expenses
          final localOnlyExpenses = localExpenses.where((localExp) {
            return !serverExpenses.list
                .any((serverExp) => expensesMatch(localExp, serverExp));
          }).toList();

          print("\nMerging Process:");
          print(
              "Found ${localOnlyExpenses.length} truly unique local-only expenses");
          if (localOnlyExpenses.isNotEmpty) {
            print("Unique local-only expense details:");
            for (var expense in localOnlyExpenses) {
              print(
                  "ID: ${expense.id}, Amount: ${expense.amount}, Category: ${expense.category}, Description: ${expense.description}");
            }

            // Combine server expenses with unique local-only expenses
            final combinedList = [...serverExpenses.list, ...localOnlyExpenses];
            // Sort by date, newest first
            combinedList.sort((a, b) => b.datetime.compareTo(a.datetime));

            // Create a combined expenses list
            final combinedExpenses = Expenses(combinedList);

            print("\nFinal Result:");
            print("Server expenses: ${serverExpenses.list.length}");
            print("Unique local-only expenses: ${localOnlyExpenses.length}");
            print("Total combined: ${combinedExpenses.list.length}");

            // Update the store with combined expenses
            expenseStore.setExpenses(combinedExpenses);
            storeExpensesInStorage(combinedExpenses);

            // Update chat with combined data
            print("\nChat Update:");
            print(
                "Previous chat message count: ${chatStore.history.messages.length}");
            chatStore.clear();
            if (combinedExpenses.list.isNotEmpty) {
              addChatMessages(combinedExpenses);
            }
            print(
                "New chat message count: ${chatStore.history.messages.length}");

            print("------- END FETCH EXPENSES -------\n");
            return combinedExpenses;
          } else {
            print("\nNo unique local-only expenses found");
            print("Using server expenses only: ${serverExpenses.list.length}");

            expenseStore.setExpenses(serverExpenses);
            storeExpensesInStorage(serverExpenses);

            // Update chat with server data
            print("\nChat Update:");
            print(
                "Previous chat message count: ${chatStore.history.messages.length}");
            chatStore.clear();
            if (serverExpenses.list.isNotEmpty) {
              addChatMessages(serverExpenses);
            }
            print(
                "New chat message count: ${chatStore.history.messages.length}");
          }

          print("------- END FETCH EXPENSES -------\n");
          return serverExpenses;
        } catch (e) {
          print("Error parsing expenses: $e");
          expenseStore.loading = false;
          print("------- END FETCH EXPENSES WITH ERROR -------\n");
          throw Exception('Failed to parse expenses: $e');
        }
      } else {
        print("Server returned error: ${response.statusCode}");
        expenseStore.loading = false;
        print("------- END FETCH EXPENSES WITH ERROR -------\n");
        throw Exception('Failed to load expenses: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching expenses: $e");
      expenseStore.loading = false;
      chatStore.addAtStart(
          TextMessage(false, "Error loading expenses: ${e.toString()}"));
      print("------- END FETCH EXPENSES WITH ERROR -------\n");
      rethrow;
    }
  }

  void addChatMessages(Expenses expenses) {
    if (expenses.isEmpty) {
      chatStore.addAtStart(TextMessage(true,
          "Just send a message loosely describing your expense to start your finance journey with AI."));
      print("Added welcome message to empty chat");
      return;
    }

    print("\n------- ADDING CHAT MESSAGES -------");
    print("Total expenses available: ${expenses.list.length}");

    // Add the 10 most recent expenses to the chat
    int count = 0;
    for (var expense in expenses.list) {
      if (count >= 10) break; // Limit to 10 expenses

      // Add the prompt if it exists
      if (expense.prompt != null && expense.prompt!.isNotEmpty) {
        chatStore.addAtStart(TextMessage(true, expense.prompt!));
        count++;
      }

      // Add the expense message
      chatStore.addAtStart(ExpenseMessage(expense));
      count++;
    }

    print("Added $count messages to chat");
    print("Final chat message count: ${chatStore.history.messages.length}");
    print("------- FINISHED ADDING CHAT MESSAGES -------\n");
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
      print("API response status: ${response.statusCode}");
    } catch (e) {
      print("API error: $e");
      return Exception("Something went wrong while connecting to server");
    }

    if (response.statusCode == 200) {
      try {
        var jsonData = jsonDecode(response.body);
        print("API response body: ${response.body}");

        // Check if response has quota information
        if (jsonData is Map<String, dynamic> &&
            (jsonData.containsKey('remainingQuota') ||
                jsonData.containsKey('dailyLimit') ||
                jsonData.containsKey('isPremium'))) {
          // Extract quota info
          final remainingQuota = jsonData['remainingQuota'] as int? ?? 0;
          final dailyLimit = jsonData['dailyLimit'] as int? ?? 5;
          final isPremium = jsonData['isPremium'] as bool? ?? false;

          // Update subscription service cache with quota info
          await _subscriptionService.updateQuotaFromResponse(
              remainingQuota: remainingQuota,
              dailyLimit: dailyLimit,
              isPremium: isPremium);

          // Also update local state
          setState(() {
            _remainingMessages = remainingQuota;
            _dailyMessageLimit = dailyLimit;
            _isPremium = isPremium;
          });

          print(
              "Updated quota from response: remaining=$remainingQuota/$dailyLimit");

          // Also extract and return the expense
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
        print("Error parsing expense: $e");
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
          if (errorData.containsKey('remainingQuota') &&
              errorData.containsKey('dailyLimit')) {
            final remainingQuota = errorData['remainingQuota'] as int? ?? 0;
            final dailyLimit = errorData['dailyLimit'] as int? ?? 5;
            final isPremium = errorData['isPremium'] as bool? ?? false;

            await _subscriptionService.updateQuotaFromResponse(
                remainingQuota: remainingQuota,
                dailyLimit: dailyLimit,
                isPremium: isPremium);

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
        print("Error parsing quota exceeded error: $e");
      }
      return "You've reached your daily limit of AI messages";
    } else if (response.statusCode == 401) {
      var errorMsg = jsonDecode(response.body)["errorMessage"] ??
          "Something went wrong while adding";
      print("Auth error: $errorMsg");
      return errorMsg;
    } else {
      print("API failure: ${response.statusCode}");
      throw Exception('Failed to add expense');
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print("\n------- APP INITIALIZATION -------");

      // First load expenses from local storage
      print("Loading expenses from local storage...");
      Expenses localExpenses = await getExpensesFromStorage();
      print("Loaded ${localExpenses.list.length} expenses from local storage");

      // Set the expenses in the store immediately and add to chat
      print("Setting expenses in the store...");
      expenseStore.setExpenses(localExpenses);
      expenseStore.loading =
          false; // Set loading to false after setting local expenses

      // Add local expenses to chat immediately
      if (!localExpenses.isEmpty) {
        print("Adding local expenses to chat history...");
        addChatMessages(localExpenses);
      } else {
        print("No local expenses to add to chat");
      }

      // Now that we've shown the local data, start fetching from the server
      try {
        print("Fetching subscription data from server...");
        // Fetch subscription data first
        await _fetchSubscriptionData();

        print("Fetching expenses from server...");
        // Then fetch expenses - this will replace the local expenses with server data
        // Don't show loading indicator since we're already showing local data
        await refreshExpenses(showLoading: false);

        print("Successfully refreshed data from server");
      } catch (e) {
        print("Error refreshing data from server: $e");
        // If server calls fail, at least we've shown the local data
        // Initialize subscription locally as fallback
        await _initializeSubscriptionLocally();
      }

      print("------- APP INITIALIZATION COMPLETE -------\n");
    });
  }

  // Fetch subscription data from server
  Future<void> _fetchSubscriptionData() async {
    try {
      // Call the quota endpoint once during initialization
      final quotaData = await _subscriptionService.getMessageQuota();
      final quota = quotaData['quota'];
      final isPremium = quota['isPremium'] as bool? ?? false;
      final remainingQuota = quota['remainingQuota'] as int? ?? 0;
      final dailyLimit = quota['dailyLimit'] as int? ?? (isPremium ? 100 : 5);

      setState(() {
        _isSubscriptionInitialized = true;
        _isPremium = isPremium;
        _remainingMessages = remainingQuota;
        _dailyMessageLimit = dailyLimit;
      });

      print(
          "Subscription initialized from server: premium=$_isPremium, remaining=$_remainingMessages/$_dailyMessageLimit");
    } catch (e) {
      print("Error fetching subscription data from server: $e");
      throw e; // Let the caller handle this
    }
  }

  // Initialize subscription locally as fallback
  Future<void> _initializeSubscriptionLocally() async {
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
    print(
        "Subscription initialized locally: premium=$_isPremium, remaining=$_remainingMessages/$_dailyMessageLimit");
  }

  Future<Expenses> getExpensesFromStorage() async {
    try {
      print("\n------- LOADING EXPENSES FROM STORAGE -------");
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString("expenses");

      print("Stored data exists: ${storedData != null}");
      if (storedData == null || storedData.isEmpty) {
        print("No stored expenses found");
        print("------- END LOADING EXPENSES -------\n");
        return Expenses(List.empty());
      }

      print("Stored data length: ${storedData.length} characters");

      // Parse the JSON
      final storedExpenses = jsonDecode(storedData);
      print("Parsed JSON type: ${storedExpenses.runtimeType}");
      print("Number of stored expenses: ${(storedExpenses as List).length}");

      // Create Expenses object
      var expenses = Expenses.fromJson(storedExpenses);

      // Log a sample of the loaded expenses
      final sampleExpenses = expenses.list
          .take(min(3, expenses.list.length))
          .map((e) =>
              "ID: ${e.id}, Amount: ${e.amount}, Category: ${e.category}")
          .join("\n");

      print("Sample loaded expenses:\n$sampleExpenses");
      print("------- END LOADING EXPENSES -------\n");

      return expenses;
    } catch (e) {
      print("ERROR LOADING EXPENSES: $e");
      print("------- END LOADING EXPENSES WITH ERROR -------\n");
      // Return empty list on error
      return Expenses(List.empty());
    }
  }

  Future<Expenses> refreshExpenses({bool showLoading = true}) {
    if (showLoading) {
      expenseStore.loading = true;
    }
    futureExpenses = fetchExpenses(showLoading: showLoading);
    return futureExpenses;
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
        print("Received Expense object in addExpense: ${userInput.id}");

        // Add the expense to the chat and store
        chatStore.addAtStart(ExpenseMessage(userInput));
        expenseStore.add(userInput);
        storeExpensesInStorage(expenseStore.expenses);

        print("Successfully added manual expense: ${userInput.id}");
        return userInput;
      } catch (e) {
        print("Error adding manual expense: $e");
        chatStore
            .addAtStart(TextMessage(false, "Error adding manual expense: $e"));
        return null;
      }
    }

    // Otherwise, treat as a message for AI processing
    String userMessage = userInput as String;

    // EasyLoading.show(status: 'loading...');
    if (userMessage == "") {
      chatStore.addAtStart(TextMessage(
          false, "Please send a message with details to add expense"));
      return null;
    }

    // Check if user can send message
    bool canSend = await _subscriptionService.canSendMessage();
    if (!canSend) {
      chatStore.addAtStart(TextMessage(false,
          "You've reached your daily message limit. Upgrade to premium for unlimited messages."));
      return null;
    }

    try {
      chatStore.addAtStart(TextMessage(true, userMessage));
      chatStore.addAtStart(AILoading());
      var result = await postExpense(userMessage);
      chatStore.pop();
      // EasyLoading.dismiss();

      if (result is Expense) {
        // Add the expense to the UI first
        chatStore.addAtStart(ExpenseMessage(result));
        expenseStore.add(result);
        storeExpensesInStorage(expenseStore.expenses);

        print("Successfully added expense: ${result.id}");
        return result;
      } else if (result is Map<String, dynamic>) {
        // This handles the case where we have both an expense and quota info
        final expense = result['expense'] as Expense;

        // Add the expense to the UI
        chatStore.addAtStart(ExpenseMessage(expense));
        expenseStore.add(expense);
        storeExpensesInStorage(expenseStore.expenses);

        // Update subscription service with quota info
        if (result.containsKey('remainingQuota')) {
          final remainingQuota = result['remainingQuota'] as int? ?? 0;
          final dailyLimit = result['dailyLimit'] as int? ?? 5;
          final isPremium = result['isPremium'] as bool? ?? false;

          // Update subscription service
          await _subscriptionService.updateQuotaFromResponse(
              remainingQuota: remainingQuota,
              dailyLimit: dailyLimit,
              isPremium: isPremium);

          // Also update local state variables
          setState(() {
            _remainingMessages = remainingQuota;
            _dailyMessageLimit = dailyLimit;
            _isPremium = isPremium;
          });
        }

        print("Successfully added expense with quota update: ${expense.id}");
        return expense;
      }

      // If we get here, the expense wasn't successfully created
      chatStore.addAtStart(TextMessage(false, result as String));
      return null;
    } catch (e) {
      developer.log(
        'Error creating expense',
        // error: jsonEncode(e),
      );
      chatStore.pop();
      chatStore.addAtStart(TextMessage(
          false, "Something went wrong while trying to connect to Finget"));
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
      print("\n------- CLEARING LOCAL STORAGE -------");
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("expenses");
      print("Removed expenses from local storage");

      // Reset the expense store
      expenseStore.setExpenses(Expenses(List.empty()));
      print("Reset expense store to empty list");

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local storage cleared')),
      );
      print("------- LOCAL STORAGE CLEARED -------\n");
    } catch (e) {
      print("Error clearing local storage: $e");
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
                Consumer<ExpenseStore>(
                  builder: (context, expenseStore, _) {
                    // Calculate budget percentage if budget has a valid total
                    double percentUsed = 0.0;
                    if (expenseStore.budget.total > 0) {
                      percentUsed = (expenseStore.expenses.total /
                              expenseStore.budget.total)
                          .clamp(0.0, 1.0);
                    }

                    final remaining =
                        expenseStore.budget.total - expenseStore.expenses.total;
                    final percentDisplay =
                        "${(percentUsed * 100).toStringAsFixed(0)}%";
                    final total = expenseStore.expenses.total;

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
                              // Total spent this month
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
                              const SizedBox(height: 4),
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
                                      color: isDark
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
