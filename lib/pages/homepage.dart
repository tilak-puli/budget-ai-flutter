import 'package:budget_ai/api.dart';
import 'package:budget_ai/components/expense_list.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter_easyloading/flutter_easyloading.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<Expenses> futureExpenses;

  Future<Expenses> fetchExpenses() async {
    final response = await ApiService().fetchExpenses();

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
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            FutureBuilder<Expenses>(
              future: futureExpenses,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ExpenseList(snapshot.data!);
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }

                return const CircularProgressIndicator();
              },
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: AIMessageInput(addExpense),
            ),
          ],
        ),
      ),
    );
  }
}

class AIMessageInput extends StatefulWidget {
  final Future<Expense> Function(dynamic userMessage) addExpense;

  const AIMessageInput(this.addExpense, {super.key});

  @override
  State<AIMessageInput> createState() => _AIMessageInputState();
}

class _AIMessageInputState extends State<AIMessageInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: _controller,
        onSubmitted: (value) async {
          await widget.addExpense(value);
          _controller.clear();
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'What\'s the expense?',
        ),
      ),
    );
  }
}
