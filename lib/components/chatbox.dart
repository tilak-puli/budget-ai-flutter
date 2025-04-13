import 'package:budget_ai/components/AI_message_input.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:budget_ai/theme/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Chatbox extends StatelessWidget {
  final Future<Expense?> Function(dynamic userInput) addExpense;
  final Map<String, dynamic>? quotaData;

  const Chatbox(this.addExpense, {super.key, this.quotaData});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? NeumorphicColors.darkPrimaryBackground
        : NeumorphicColors.lightPrimaryBackground;

    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Consumer<ChatStore>(
      builder: (context, chatStore, child) {
        return Column(
          children: [
            // Chat messages
            Expanded(
              child: Container(
                color: backgroundColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: ListView.builder(
                    reverse: true,
                    itemCount: chatStore.history.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatStore.history.messages[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          left: message.isUserMessage ? 100.0 : 5.0,
                          right: message.isUserMessage ? 5.0 : 100.0,
                          top: 4.0,
                          bottom: 4.0,
                        ),
                        child: Align(
                          alignment: message.isUserMessage
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: message.render(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Message input
            Container(
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.8),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
              ),
              child: AIMessageInput(
                onAddMessage: (userInput) => onAddMessage(userInput, chatStore),
                isDisabled: chatStore.history.messages.isNotEmpty &&
                    chatStore.history.messages.last is AILoading,
                remainingMessages: quotaData?['remainingMessages'],
                dailyLimit: quotaData?['dailyLimit'],
                isPremium: quotaData?['isPremium'],
              ),
            ),
          ],
        );
      },
    );
  }
}
