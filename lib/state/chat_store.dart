import 'package:budget_ai/components/expense_card.dart';
import 'package:budget_ai/components/typing_indicator.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/theme/index.dart';
import 'package:flutter/material.dart';

class ChatStore extends ChangeNotifier {
  ChatHistory history = ChatHistory();

  void addMessage(ChatMessage message) {
    history.add(message);

    notifyListeners();
  }

  void clear() {
    history.messages.clear();

    notifyListeners();
  }

  void addAtStart(ChatMessage chatMessage) {
    history.addAtStart(chatMessage);

    notifyListeners();
  }

  void updateMessage(String expenseId, ChatMessage chatMessage) {
    history.update(expenseId, chatMessage);

    notifyListeners();
  }

  void remove(String expenseId) {
    history.remove(expenseId);

    notifyListeners();
  }

  void pop() {
    history.pop();

    notifyListeners();
  }
}

abstract class ChatMessage {
  late bool isUserMessage;
  late String? expenseId;

  ChatMessage(this.isUserMessage, this.expenseId);

  Widget render();
}

class TextMessage extends ChatMessage {
  String text;

  TextMessage(bool isUserMessage, this.text) : super(isUserMessage, null);

  @override
  Widget render() {
    final isDark = GlobalKey().currentContext != null
        ? Theme.of(GlobalKey().currentContext!).brightness == Brightness.dark
        : (GlobalContext.context != null
            ? Theme.of(GlobalContext.context).brightness == Brightness.dark
            : false);

    // User messages use accent color in light/dark modes, AI messages match card background
    final messageColor = isUserMessage
        ? isDark
            ? NeumorphicColors
                .darkAccent // Blue accent for user messages in dark mode
            : NeumorphicColors.lightAccent
                .withOpacity(0.15) // Light blue background for user messages
        : isDark
            ? NeumorphicColors.darkCardBackground
            : Colors.white;

    // Text color based on background contrast
    final textColor = isUserMessage
        ? isDark
            ? Colors.white // White text on dark blue background
            : NeumorphicColors.lightTextPrimary // Blue text on light background
        : isDark
            ? Colors.white // White text on dark cards
            : NeumorphicColors
                .lightTextPrimary; // Dark text on light backgrounds

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
      child: Container(
        decoration: NeumorphicBox.decoration(
          context: GlobalKey().currentContext ?? GlobalContext.context,
          color: messageColor,
          borderRadius: 16.0, // Increased border radius for modern look
          depth: isDark ? 2.0 : 4.0, // Reduced depth in dark mode
          intensity: isDark ? 0.2 : 0.4, // Lower intensity for subtle effect
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class ExpenseMessage extends ChatMessage {
  late Expense expense;

  ExpenseMessage(this.expense) : super(false, expense.id);

  @override
  Widget render() {
    final isDark = GlobalKey().currentContext != null
        ? Theme.of(GlobalKey().currentContext!).brightness == Brightness.dark
        : (GlobalContext.context != null
            ? Theme.of(GlobalContext.context).brightness == Brightness.dark
            : false);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
      child: Container(
        decoration: NeumorphicBox.decoration(
          context: GlobalKey().currentContext ?? GlobalContext.context,
          color: isDark ? NeumorphicColors.darkCardBackground : Colors.white,
          borderRadius: 12.0,
          depth: 4.0,
          intensity: isDark ? 0.4 : 0.8, // Lower intensity for dark mode
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
          child: ExpenseCard(
            expense,
            inChatMessage: true,
          ),
        ),
      ),
    );
  }
}

class AILoading extends ChatMessage {
  AILoading() : super(false, null);

  @override
  Widget render() {
    return const TypingIndicator(showIndicator: true);
  }
}

enum MessageType { text, expense }

class ChatHistory {
  List<ChatMessage> messages = List.empty(growable: true);

  add(ChatMessage message) {
    messages.add(message);
  }

  addAtStart(ChatMessage message) {
    messages.insert(0, message);
  }

  void pop() {
    messages.removeAt(0);
  }

  void update(String expenseId, ChatMessage updated) {
    var messageIndex =
        messages.indexWhere((element) => element.expenseId == expenseId);

    if (messageIndex != -1) {
      messages[messageIndex] = updated;
    }
  }

  void remove(String expenseId) {
    messages.removeWhere((element) => element.expenseId == expenseId);
  }
}

// Add this class to provide context for NeumorphicBox when needed
class GlobalContext {
  static late BuildContext context;
}
