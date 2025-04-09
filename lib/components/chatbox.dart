import 'package:budget_ai/components/AI_message_input.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Chatbox extends StatelessWidget {
  final Future<Expense?> Function(dynamic userInput) addExpense;

  const Chatbox(this.addExpense, {super.key});

  // Handle both string messages and Expense objects
  Future<void> onAddMessage(dynamic userInput, ChatStore chatStore) async {
    // Process different types of inputs - handle both strings and Expense objects directly
    try {
      await addExpense(userInput);
    } catch (e) {
      print("Error processing user input: $e");
      // Show error in chat
      chatStore.addAtStart(TextMessage(
          false, "Failed to process the expense. Please try again."));
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
        AIMessageInput(
          onAddMessage: (userInput) => onAddMessage(userInput, chatStore),
          isDisabled: chatStore.history.messages.isNotEmpty &&
              chatStore.history.messages.last is AILoading,
        )
      ]);
    });
  }
}
