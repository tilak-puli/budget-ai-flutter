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

  Expenses mergeExpenses(Expenses newExpenses) {
    List<Expense> mergedList = mergeSortedLists<Expense>(
      expenses.list,
      newExpenses.list,
      (Expense a, Expense b) => b.datetime
          .compareTo(a.datetime), // Sort by datetime in descending order
    );

    expenses = Expenses(mergedList);
    storeExpensesInStorage(expenses);
    notifyListeners();
    return expenses;
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

List<T> mergeSortedLists<T>(
  List<T> list1,
  List<T> list2,
  int Function(T a, T b) compare,
) {
  List<T> mergedList = [];
  int i = 0, j = 0;

  while (i < list1.length && j < list2.length) {
    if (compare(list1[i], list2[j]) <= 0) {
      mergedList.add(list1[i]);
      i++;
    } else {
      mergedList.add(list2[j]);
      j++;
    }
  }

  // Add remaining elements from either list
  while (i < list1.length) {
    mergedList.add(list1[i]);
    i++;
  }

  while (j < list2.length) {
    mergedList.add(list2[j]);
    j++;
  }

  return mergedList;
}
