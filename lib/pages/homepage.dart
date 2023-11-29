import 'package:budget_ai/api.dart';
import 'package:budget_ai/components/AI_message_input.dart';
import 'package:budget_ai/components/body_tabs.dart';
import 'package:budget_ai/components/budget_status.dart';
import 'package:budget_ai/components/leading_actions.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:budget_ai/utils/time.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_easyloading/flutter_easyloading.dart';

var todayDate = DateTime.now();

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<Expenses> futureExpenses;
  DateTime fromDate = getMonthStart(todayDate);
  DateTime toDate = getMonthEnd(todayDate);

  Future<Expenses> fetchExpenses() async {
    final response = await ApiService().fetchExpenses(fromDate, toDate);

    if (response.statusCode == 200) {
      return Expenses.fromJson(jsonDecode(response.body) as List<dynamic>);
    } else {
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
    refreshExpenses();
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
                child: FutureBuilder<Expenses>(
                  future: futureExpenses,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Column(
                        children: [
                          BudgetStatus(snapshot.data!),
                          BodyTabs(snapshot.data!),
                        ],
                      );
                    } else if (snapshot.hasError) {
                      return Text('${snapshot.error}');
                    }

                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
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
