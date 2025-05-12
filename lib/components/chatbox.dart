import 'package:budget_ai/components/AI_message_input.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:budget_ai/theme/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:budget_ai/api.dart';

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

  // Function to show the report dialog
  void _showReportDialog(BuildContext context, String expenseId) {
    final TextEditingController reportController = TextEditingController();
    final chatStore = Provider.of<ChatStore>(context, listen: false);
    Expense? expense;
    for (var m in chatStore.history.messages) {
      if (m is ExpenseMessage && m.expense.id == expenseId) {
        expense = m.expense;
        break;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = isDark
            ? NeumorphicColors.darkPrimaryBackground
            : NeumorphicColors.lightPrimaryBackground;
        final accent = Theme.of(context).colorScheme.primary;
        return Dialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Incorrect AI Response',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: isDark
                        ? NeumorphicColors.darkTextPrimary
                        : NeumorphicColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please let us know what was incorrect about this expense entry:',
                  style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w400, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reportController,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: isDark
                        ? NeumorphicColors.darkTextPrimary
                        : NeumorphicColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Optional: Describe the issue...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? NeumorphicColors.darkTextSecondary
                          : NeumorphicColors.lightTextSecondary,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.black.withOpacity(0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? NeumorphicColors.darkAccent.withOpacity(0.2)
                            : NeumorphicColors.lightAccent.withOpacity(0.2),
                        width: 1.2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 14),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? NeumorphicColors.darkTextSecondary
                            : NeumorphicColors.lightTextSecondary,
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (expense != null) {
                          ApiService().reportAIExpense(
                            expense,
                            message: reportController.text,
                          );
                        }
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thank you for your feedback!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Send Report'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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

        // Find the latest expense message for the report button
        ChatMessage? latestExpenseMessage;
        for (int i = chatStore.history.messages.length - 1; i >= 0; i--) {
          if (chatStore.history.messages[i] is ExpenseMessage) {
            latestExpenseMessage = chatStore.history.messages[i];
            break;
          }
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
                    bool isLatestExpenseMessage =
                        message == latestExpenseMessage;

                    return Padding(
                      padding: EdgeInsets.only(
                        left: message.isUserMessage ? 100.0 : 5.0,
                        right: message.isUserMessage ? 5.0 : 100.0,
                        top: 4.0,
                        bottom: 4.0,
                      ),
                      child: Column(
                        crossAxisAlignment: message.isUserMessage
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: message.isUserMessage
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: message.render(),
                          ),
                          // Show report button only below the most recent expense message
                          if (isLatestExpenseMessage)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 2.0, left: 8.0),
                              child: GestureDetector(
                                onTap: () => _showReportDialog(context,
                                    (message as ExpenseMessage).expense.id),
                                child: const Text(
                                  "Spot an error? Help us improve AI.",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
