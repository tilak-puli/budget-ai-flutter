import 'package:budget_ai/components/AI_message_input.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:budget_ai/theme/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Chatbox extends StatefulWidget {
  final Future<Expense?> Function(dynamic userInput) addExpense;
  final Map<String, dynamic>? quotaData;

  const Chatbox(this.addExpense, {super.key, this.quotaData});

  @override
  State<Chatbox> createState() => _ChatboxState();
}

class _ChatboxState extends State<Chatbox> {
  // Add a scroll controller to manage scrolling behavior
  final ScrollController _scrollController = ScrollController();

  // Handle both string messages and Expense objects
  Future<void> onAddMessage(dynamic userInput, ChatStore chatStore) async {
    // Process different types of inputs - handle both strings and Expense objects directly
    try {
      await widget.addExpense(userInput);
      // Scroll to bottom after message is added
      _scrollToBottom();
    } catch (e) {
      print("Error processing user input: $e");
      // Show error in chat
      chatStore.addAtStart(TextMessage(
          false, "Failed to process the expense. Please try again."));
    }
  }

  // Function to scroll to the bottom of the chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        // Trigger scroll to bottom when messages change
        if (chatStore.history.messages.isNotEmpty) {
          _scrollToBottom();
        }

        return Column(
          children: [
            // Chat messages
            Expanded(
              child: Container(
                color: backgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 16.0),
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

            // Message counter with clear visual separation
            if (widget.quotaData != null &&
                !(widget.quotaData?['isPremium'] ?? false))
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 1,
                      offset: const Offset(0, -1),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1.0,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                margin: const EdgeInsets.only(bottom: 2.0),
                alignment: Alignment.center,
                child: Text(
                  "${widget.quotaData?['remainingMessages'] ?? 0} of ${widget.quotaData?['dailyLimit'] ?? 5} free messages left",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
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
                remainingMessages: widget.quotaData?['remainingMessages'],
                dailyLimit: widget.quotaData?['dailyLimit'],
                isPremium: widget.quotaData?['isPremium'],
              ),
            ),
          ],
        );
      },
    );
  }
}
