import 'package:budget_ai/components/expense_card.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:flutter/material.dart';

class AIMessageInput extends StatefulWidget {
  final void Function(dynamic userMessage) addExpense;

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
      child: Row(
        children: [
          Expanded(
              child: TextField(
            autofocus: false,
            controller: _controller,
            onSubmitted: (value) async {
              widget.addExpense(value);
              _controller.clear();
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'What\'s the expense?',
              filled: true,
              fillColor: Colors.white,
            ),
          )),
          Padding(
            padding: const EdgeInsets.only(left: 2.0),
            child: Container(
              height: 50,
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Theme.of(context).colorScheme.primary,
              ),
              child: IconButton(
                  color: Colors.white,
                  onPressed: () async {
                    widget.addExpense(_controller.text);
                    _controller.clear();
                  },
                  icon: const Icon(Icons.send)),
            ),
          )
        ],
      ),
    );
  }
}
