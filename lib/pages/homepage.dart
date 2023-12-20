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
import 'dart:convert';
import 'package:provider/provider.dart';

var todayDate = DateTime.now();

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
    final response = await ApiService().fetchExpenses(fromDate, toDate);

    if (response.statusCode == 200) {
      var expenses =
          Expenses.fromJson(jsonDecode(response.body) as List<dynamic>);
      expenseStore.loading = false;

      expenseStore.setExpenses(expenses);

      chatStore.clear();

      for (var expense in expenses.list.take(10)) {
        chatStore.addMessage(ExpenseMessage(expense));
        chatStore.addMessage(TextMessage(true, expense.prompt ?? ""));
      }

      return expenses;
    } else {
      expenseStore.loading = false;
      throw Exception('Failed to load expenses');
    }
  }

  Future<Object> postExpense(userMessage) async {
    final response = await ApiService().addExpense(userMessage);

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshExpenses();
    });
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
    try {
      chatStore.addAtStart(TextMessage(true, userMessage));
      var expense = await postExpense(userMessage);

      // EasyLoading.dismiss();

      if (expense is Expense) {
        refreshExpenses(showLoading: false);

        return expense;
      }

      chatStore.addAtStart(TextMessage(false, expense as String));
      return null;
    } catch (e) {
      chatStore.addAtStart(
          TextMessage(false, "Something went wrong while trying to ask Finly"));
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
                      const BudgetStatus(),
                      BodyTabs(addExpense),
                    ],
                  ),
          ]),
        ),
      ),
    );
  }
}
