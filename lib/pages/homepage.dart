import 'dart:math';

import 'package:budget_ai/components/expense_list.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<Expenses> futureExpenses;

  Future<Expenses> fetchExpenses() async {
    final response =
        await http.get(Uri.parse('http://localhost:3000/expenses'));

    if (response.statusCode == 200) {
      return Expenses.fromJson(jsonDecode(response.body) as List<dynamic>);
    } else {
      throw Exception('Failed to load expenses');
    }
  }

  Future<Expense> postExpense(userMessage) async {
    final response =
        await http.post(Uri.parse('http://localhost:3000/ai/expense'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(<String, String>{"userMessage": userMessage}));

    if (response.statusCode == 200) {
      return Expense.fromJson(jsonDecode(response.body) );
    } else {
      throw Exception('Failed to load expenses');
    }
  }

  @override
  void initState() {
    super.initState();
    refreshExpenses();
  }

  Future<Expenses> refreshExpenses() => futureExpenses = fetchExpenses();

  Future<Expense> addExpense(userMessage) async {
    var expense = await postExpense(userMessage);

    await refreshExpenses();

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
        onSubmitted: (value) {
          widget.addExpense(value);
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'What\'s the expense?',
        ),
      ),
    );
  }
}
