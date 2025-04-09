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
      response = await ApiService().fetchExpenses(fromDate, toDate);
    } catch (e) {
      chatStore.addAtStart(TextMessage(false, e.toString()));
      rethrow;
    }
    ;

    if (response.statusCode == 200) {
      var expenses =
          Expenses.fromJson(jsonDecode(response.body) as List<dynamic>);
      expenseStore.loading = false;

      expenses = expenseStore.mergeExpenses(expenses);

      chatStore.clear();

      addChatMessages(expenses);

      return expenses;
    } else {
      expenseStore.loading = false;
      throw Exception('Failed to load expenses');
    }
  }

  void addChatMessages(Expenses expenses) {
    for (var expense in expenses.list.take(10)) {
      chatStore.addMessage(ExpenseMessage(expense));
      chatStore.addMessage(TextMessage(true, expense.prompt ?? ""));
    }

    if (expenses.isEmpty) {
      chatStore.addMessage(TextMessage(true,
          "Just send a message loosely describing you exprense to start your finance journey with AI."));
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
      // Initialize subscription service
      await _subscriptionService.initializeSubscriptions();
      final isPremium = await _subscriptionService.isPremium();
      setState(() {
        _isSubscriptionInitialized = true;
        _isPremium = isPremium;
      });

      Expenses expenses = await getExpensesFromStorage();
      expenseStore.setExpenses(expenses);
      addChatMessages(expenses);

      refreshExpenses(showLoading: false);
    });
  }

  Future<Expenses> getExpensesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    var storedExpenses = jsonDecode(prefs.getString("expenses") ?? "[]");
    var expenses = Expenses.fromJson(storedExpenses as List<dynamic>);
    return expenses;
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

  Future<Expense?> addExpense(userMessage) async {
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
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset_count',
                child: Text('Reset Message Count (DEV)'),
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
