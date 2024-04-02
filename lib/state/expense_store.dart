import 'dart:convert';

import 'package:budget_ai/models/budget.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> storeExpensesInStorage(Expenses expenses) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("expenses", jsonEncode(expenses.list));
}

class ExpenseStore extends ChangeNotifier {
  Expenses expenses = Expenses(List.empty());
  bool loading = false;
  Budget budget = Budget();

  void setExpenses(Expenses expenses) {
    this.expenses = expenses;
    storeExpensesInStorage(expenses);

    notifyListeners();
  }

  void deleteExpense(id) {
    expenses.remove(id);
    storeExpensesInStorage(expenses);

    notifyListeners();
  }

  void updateExpense(String id, Expense expense) {
    expenses.update(id, expense);
    storeExpensesInStorage(expenses);

    notifyListeners();
  }

  void updateBudgetAmount(String category, int newAmount) {
    budget.updateAmount(category, newAmount);

    notifyListeners();
  }

  void add(Expense expense) {
    expenses.add(expense);
    storeExpensesInStorage(expenses);

    notifyListeners();
  }
}
