import 'package:budget_ai/components/expense_card.dart';
import 'package:budget_ai/components/typing_indicator.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:flutter/material.dart';

class ChatStore extends ChangeNotifier {
  ChatHistory history = ChatHistory();

  void addMessage(ChatMessage message) {
    history.add(message);

    notifyListeners();
  }

  void clear() {
    history.messages.clear();
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
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
      child: Material(
        elevation: 1.0,
        borderRadius: BorderRadius.circular(12.0),
        color: isUserMessage ? Color(0xFFD5EFFA) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
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
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
      child: Material(
        elevation: 1.0,
        borderRadius: BorderRadius.circular(12.0),
        color: Colors.white,
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
