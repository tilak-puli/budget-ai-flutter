import 'package:budget_ai/models/budget.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:flutter/material.dart';

class ExpenseStore extends ChangeNotifier{
  Expenses expenses = Expenses(List.empty());
  bool loading = false;
  Budget budget = Budget();

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

  void updateBudgetAmount(String category, int newAmount) {
    budget.updateAmount(category, newAmount);

   notifyListeners(); 
  }

  void add(Expense expense) {
    expenses.add(expense);

    notifyListeners();
  }
}
