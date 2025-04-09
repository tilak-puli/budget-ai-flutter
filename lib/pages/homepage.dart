import 'package:budget_ai/api.dart';
import 'package:budget_ai/components/body_tabs.dart';
import 'package:budget_ai/components/budget_status.dart';
import 'package:budget_ai/components/leading_actions.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:budget_ai/screens/subscription_screen.dart';
import 'package:budget_ai/screens/profile_screen.dart';
import 'package:budget_ai/services/subscription_service.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:budget_ai/utils/time.dart';
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

  DateTime fromDate = getMonthStart(todayDate);
  DateTime toDate = getMonthEnd(todayDate);

  Future<Expenses> fetchExpenses({bool showLoading = true}) async {
    expenseStore.loading = showLoading;
    var response;

    try {
      print("\n------- FETCH EXPENSES FROM SERVER -------");
      print(
          "Fetching expenses from server for ${fromDate.toIso8601String()} to ${toDate.toIso8601String()}");
      response = await ApiService().fetchExpenses(fromDate, toDate);
      print("Fetch response status: ${response.statusCode}");

      // Log the response size
      print("Response body length: ${response.body.length} characters");

      if (response.statusCode == 200) {
        try {
          var jsonData = jsonDecode(response.body) as List<dynamic>;
          print("Server returned ${jsonData.length} expenses");

          // Log the IDs of server expenses
          final serverIds =
              jsonData.map((item) => item['_id'].toString()).toList();
          print("Server expense IDs: ${serverIds.join(', ')}");

          // Log existing local expenses
          final localIds = expenseStore.expenses.list.map((e) => e.id).toList();
          print("Local expense IDs: ${localIds.join(', ')}");

          var serverExpenses = Expenses.fromJson(jsonData);
          expenseStore.loading = false;

          // Check for duplicate IDs in server response
          final serverExpenseIds = <String>{};
          final duplicates = <String>[];
          for (var expense in serverExpenses.list) {
            if (serverExpenseIds.contains(expense.id)) {
              duplicates.add(expense.id);
            } else {
              serverExpenseIds.add(expense.id);
            }
          }

          if (duplicates.isNotEmpty) {
            print(
                "WARNING: Found duplicate IDs in server response: ${duplicates.join(', ')}");
          }

          // Merge with existing expenses, prioritizing server data
          var mergedExpenses = expenseStore.mergeExpenses(serverExpenses);

          // Only clear and update chat if we have new data
          if (serverExpenses.list.isNotEmpty) {
            chatStore.clear();
            addChatMessages(mergedExpenses);
          }

          print("------- END FETCH EXPENSES -------\n");
          return mergedExpenses;
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
      chatStore.addMessage(TextMessage(true,
          "Just send a message loosely describing your expense to start your finance journey with AI."));
      return;
    }

    // Add the 10 most recent expenses to the chat
    int count = 0;
    for (var expense in expenses.list) {
      chatStore.addMessage(ExpenseMessage(expense));
      if (expense.prompt != null && expense.prompt!.isNotEmpty) {
        chatStore.addMessage(TextMessage(true, expense.prompt!));
      }

      count++;
      if (count >= 10) break; // Limit to 10 expenses
    }

    print("Added $count expenses to chat history");
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
        print(
            "Received expense data: ${jsonData.toString().substring(0, min(50, jsonData.toString().length))}...");
        return Expense.fromJson(jsonData);
      } catch (e) {
        print("Error parsing expense: $e");
        return "Failed to parse the expense data";
      }
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
      // Initialize subscription service
      await _subscriptionService.initializeSubscriptions();
      final isPremium = await _subscriptionService.isPremium();
      setState(() {
        _isSubscriptionInitialized = true;
        _isPremium = isPremium;
      });
      print("Subscription initialized, premium status: $_isPremium");

      // First load expenses from local storage
      print("Loading expenses from local storage...");
      Expenses localExpenses = await getExpensesFromStorage();
      print("Loaded ${localExpenses.list.length} expenses from local storage");

      // Set the expenses in the store
      print("Setting expenses in the store...");
      expenseStore.setExpenses(localExpenses);

      // Add messages to the chat interface
      if (!localExpenses.isEmpty) {
        print("Adding expenses to chat history...");
        addChatMessages(localExpenses);
      } else {
        print("No local expenses to add to chat");
      }

      // Then fetch from server and merge
      try {
        print("Fetching expenses from server...");
        await refreshExpenses(showLoading: false);
        print("Successfully refreshed expenses from server");
      } catch (e) {
        print("Error refreshing expenses from server: $e");
        // If we fail to load from the server, at least we have local data
      }
      print("------- APP INITIALIZATION COMPLETE -------\n");
    });
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
    setState(() => {});
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
      var expense = await postExpense(userMessage);
      chatStore.pop();
      // EasyLoading.dismiss();

      if (expense is Expense) {
        // Add the expense to the UI first
        chatStore.addAtStart(ExpenseMessage(expense));
        expenseStore.add(expense);
        storeExpensesInStorage(expenseStore.expenses);

        // Increment message count ONLY after successful expense creation
        await _subscriptionService.incrementMessageCount();

        print("Successfully added expense: ${expense.id}");
        return expense;
      }

      // If we get here, the expense wasn't successfully created
      chatStore.addAtStart(TextMessage(false, expense as String));
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Row(
          children: [
            Text(widget.title),
            if (_isPremium)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.workspace_premium,
                  size: 18,
                  color: Colors.amber,
                ),
              ),
          ],
        ),
        leading: LeadingActions(fromDate, toDate, updateTimeFrame),
        actions: [
          IconButton(
            icon: const Icon(Icons.diamond_outlined),
            onPressed: _showSubscriptionDialog,
            tooltip: 'Upgrade to Premium',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'reset_count') {
                // Reset message count for testing (DEV ONLY)
                await _subscriptionService.resetMessageCount();
                // Show a snackbar confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Message count reset for testing')),
                );
              } else if (value == 'clear_storage') {
                // Clear local storage (DEV ONLY)
                await clearLocalStorage();
                // Refresh from server
                await refreshExpenses(showLoading: true);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset_count',
                child: Text('Reset Message Count (DEV)'),
              ),
              const PopupMenuItem(
                value: 'clear_storage',
                child: Text('Clear Storage & Reload (DEV)'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomProfileScreen(),
                ),
              );
            },
          )
        ],
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: Stack(children: [
            expenseStore.loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      BudgetStatus(toDate.month == todayDate.month
                          ? 'This month'
                          : "${months[toDate.month - 1]} month"),
                      const SizedBox(height: 10),
                      BodyTabs(addExpense),
                    ],
                  ),
          ]),
        ),
      ),
    );
  }
}
