import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:flutter/material.dart';

class ExpenseStore extends ChangeNotifier{
  Expenses expenses = Expenses(List.empty());
  bool loading = false;

  void setExpenses(Expenses expenses) {
    this.expenses = expenses;

    notifyListeners();
  }

  void deleteExpense(id) {
    expenses.remove(id);

    notifyListeners();
  }

  void updateExpense(String id, Expense expense) {
    expenses.update(id, expense);

    notifyListeners();
  }
}
