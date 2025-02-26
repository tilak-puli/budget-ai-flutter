import 'package:budget_ai/api.dart';
import 'package:budget_ai/components/body_tabs.dart';
import 'package:budget_ai/components/budget_status.dart';
import 'package:budget_ai/components/leading_actions.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:budget_ai/utils/time.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/src/response.dart';
import 'dart:convert';
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
    } catch (e) {
      return Exception("Something went wrong while connecting to server");
    }

    if (response.statusCode == 200) {
      return Expense.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      return jsonDecode(response.body)["errorMessage"] ??
          "Something went wrong while adding";
    } else {
      throw Exception('Failed to add expense');
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
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

    try {
      chatStore.addAtStart(TextMessage(true, userMessage));
      chatStore.addAtStart(AILoading());
      var expense = await postExpense(userMessage);
      chatStore.pop();
      // EasyLoading.dismiss();

      if (expense is Expense) {
        chatStore.addAtStart(ExpenseMessage(expense));
        expenseStore.add(expense);
        storeExpensesInStorage(expenseStore.expenses);

        return expense;
      }

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

  @override
  Widget build(BuildContext context) {
    expenseStore = Provider.of<ExpenseStore>(context, listen: true);
    chatStore = Provider.of<ChatStore>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(widget.title),
        leading: LeadingActions(fromDate, toDate, updateTimeFrame),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder: (context) => ProfileScreen(
                    appBar: AppBar(
                      title: const Text('User Profile'),
                    ),
                    actions: [
                      SignedOutAction((context) {
                        Navigator.of(context).pop();
                      })
                    ],
                  ),
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
