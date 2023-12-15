import 'package:budget_ai/models/expense.dart';
import 'package:flutter/material.dart';

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
      width: MediaQuery.of(context).size.width - 20,
      child: TextField(
        autofocus: true,
        controller: _controller,
        onSubmitted: (value) async {
          await widget.addExpense(value);
          _controller.clear();
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'What\'s the expense?',
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
