import 'package:budget_ai/components/expenseList.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text(widget.title),
      ),
      body: const Center(
        child: Column(
          children: [
            ExpenseList(),
            Padding(
              padding: EdgeInsets.all(10.0),
              child: AIMessageInput(),
            ),
          ],
        ),
      ),
    );
  }
}

class AIMessageInput extends StatelessWidget {
  const AIMessageInput({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 50,
      child: TextField(
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'What\'s the expense?',
        ),
      ),
    );
  }
}
