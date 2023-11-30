import 'package:budget_ai/api.dart';
import 'package:budget_ai/components/ai_message_input.dart';
import 'package:budget_ai/components/body_tabs.dart';
import 'package:budget_ai/components/budget_status.dart';
import 'package:budget_ai/components/leading_actions.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:budget_ai/utils/time.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_easyloading/flutter_easyloading.dart';
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
  DateTime fromDate = getMonthStart(todayDate);
  DateTime toDate = getMonthEnd(todayDate);

  Future<Expenses> fetchExpenses() async {
    expenseStore.loading = true;
    final response = await ApiService().fetchExpenses(fromDate, toDate);

    if (response.statusCode == 200) {
      var expenses =
          Expenses.fromJson(jsonDecode(response.body) as List<dynamic>);
      expenseStore.loading = false;

      expenseStore.setExpenses(expenses);
      return expenses;
    } else {
      expenseStore.loading = false;
      throw Exception('Failed to load expenses');
    }
  }

  Future<Expense> postExpense(userMessage) async {
    final response = await ApiService().addExpense(userMessage);

    if (response.statusCode == 200) {
      return Expense.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load expenses');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshExpenses();
    });
  }

  void refreshExpenses() {
    setState(() => {});
    futureExpenses = fetchExpenses();
  }

  Future<void> updateTimeFrame(newFromDate, newToDate) async {
    setState(() {
      fromDate = newFromDate;
      toDate = newToDate;
    });
    refreshExpenses();
  }

  Future<Expense> addExpense(userMessage) async {
    EasyLoading.show(status: 'loading...');
    var expense = await postExpense(userMessage);

    refreshExpenses();
    EasyLoading.dismiss();

    return expense;
  }

  @override
  Widget build(BuildContext context) {
    expenseStore = Provider.of<ExpenseStore>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(widget.title),
        leading: LeadingActions(fromDate, toDate, updateTimeFrame),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: Expanded(
            child: Column(children: [
              Expanded(
                  child: expenseStore.loading
                      ? const Center(child: CircularProgressIndicator())
                      : const Column(
                          children: [
                            BudgetStatus(),
                            BodyTabs(),
                          ],
                        )),
              Positioned(
                bottom: 20,
                child: AIMessageInput(addExpense),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
