import 'package:budget_ai/components/ai_message_input.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Chatbox extends StatelessWidget {
  final Future<Expense?> Function(String userMessage) addExpense;

  const Chatbox(this.addExpense, {super.key});

  Future<void> onAddMessage(userMessage, ChatStore chatStore) async {
    chatStore.addMessage(TextMessage(true, userMessage));
    Expense? expense = await addExpense(userMessage);

    if(expense != null) {
      chatStore.addMessage(ExpenseMessage(expense));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatStore>(builder: (context, chatStore, child) {
      return Column(children: [
        Expanded(
            child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Center(
            child: ListView(
                reverse: true,
                children: chatStore.history.messages
                    .map((e) => Align(
                        alignment: e.isUserMessage
                            ? Alignment.bottomRight
                            : Alignment.bottomLeft,
                        child: SizedBox(width: 300, child: e.render())))
                    .toList()),
          ),
        )),
        AIMessageInput((message) => onAddMessage(message, chatStore))
      ]);
    });
  }
}
