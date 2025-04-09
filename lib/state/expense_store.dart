import 'dart:convert';
import 'dart:math';

import 'package:budget_ai/models/budget.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> storeExpensesInStorage(Expenses expenses) async {
  try {
    print("\n------- STORING EXPENSES LOCALLY -------");
    print("Storing ${expenses.list.length} expenses");

    // Convert to JSON and serialize
    final serialized = jsonEncode(expenses.list);

    // Get the first few expenses for logging
    final sampleExpenses = expenses.list
        .take(3)
        .map((e) => "ID: ${e.id}, Amount: ${e.amount}, Category: ${e.category}")
        .join("\n");

    print("Sample expenses to store:\n$sampleExpenses");
    print("Total serialized length: ${serialized.length} characters");

    // Store in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("expenses", serialized);

    // Verify storage
    final savedData = prefs.getString("expenses");
    print("Verification - Data stored: ${savedData != null}");
    print("Verification - Data length: ${savedData?.length ?? 0} characters");
    print("------- EXPENSES STORED LOCALLY -------\n");
  } catch (e) {
    print("ERROR STORING EXPENSES: $e");
  }
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
    print("\n------- MERGING EXPENSES -------");
    print("Local expenses count: ${expenses.list.length}");
    print("Server expenses count: ${newExpenses.list.length}");

    if (newExpenses.list.isEmpty) {
      print("No server expenses received, keeping existing expenses");
      print("------- END MERGE (NO CHANGES) -------\n");
      return expenses;
    }

    // Since server returns all expenses, we'll completely
    // replace local expenses with server expenses

    // Sort server expenses by datetime (newest first)
    final sortedServerExpenses = List<Expense>.from(newExpenses.list);
    sortedServerExpenses.sort((a, b) => b.datetime.compareTo(a.datetime));

    print(
        "Replacing local expenses with ${sortedServerExpenses.length} server expenses");

    // Log a few server expenses
    if (sortedServerExpenses.isNotEmpty) {
      final sampleExpenses = sortedServerExpenses
          .take(min(3, sortedServerExpenses.length))
          .map((e) =>
              "ID: ${e.id}, Date: ${e.datetime.toIso8601String()}, Amount: ${e.amount}, Category: ${e.category}")
          .join("\n");
      print("Sample server expenses:\n$sampleExpenses");
    }

    print("------- END MERGE -------\n");

    // Replace local expenses with server expenses
    expenses = Expenses(sortedServerExpenses);
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
    // First check if expense with this ID already exists
    var existingIndex = expenses.list.indexWhere((e) => e.id == expense.id);

    if (existingIndex != -1) {
      // Update existing expense
      expenses.update(expense.id, expense);
    } else {
      // Add new expense
      expenses.add(expense);
    }

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
