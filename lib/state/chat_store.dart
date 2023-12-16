import 'package:budget_ai/components/expense_card.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:flutter/material.dart';

class ChatStore extends ChangeNotifier{
  ChatHistory history = ChatHistory();

  void addMessage(ChatMessage message) {
    history.add(message);

    notifyListeners();
  }

  void clear() {
    history.messages.clear();
  }

  void addAtStart(TextMessage textMessage) {
    history.addAtStart(textMessage);

    notifyListeners();
  }
}

abstract class ChatMessage {
  late bool isUserMessage;

  ChatMessage(this.isUserMessage);

  Widget render();
}

class TextMessage extends ChatMessage{
  String text;

  TextMessage(bool isUserMessage, this.text): super(isUserMessage);

  @override
  Widget render() {
    return Card(child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text),
    ));
  }

}

class ExpenseMessage extends ChatMessage{
  late Expense expense;

  ExpenseMessage(this.expense): super(false);

  @override
  Widget render() {
    return Card(child: ExpenseCard(expense));
  }

}


enum MessageType {
  text,
  expense
}

class ChatHistory {
  List<ChatMessage> messages = List.empty(growable: true);

  add(ChatMessage message) {
    messages.add(message);
  }

  addAtStart(ChatMessage message) {
    messages.insert(0, message);
  }
}
