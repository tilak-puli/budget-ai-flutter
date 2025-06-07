import 'dart:convert';
import 'dart:math';

import 'package:finly/models/budget.dart';
import 'package:finly/models/expense.dart';
import 'package:finly/models/expense_list.dart';
import 'package:finly/state/budget_store.dart';
import 'package:finly/models/app_init_response.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

Future<void> storeExpensesInStorage(Expenses expenses) async {
  try {
    // Convert to JSON and serialize
    final serialized = jsonEncode(expenses.list);
    // Store in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("expenses", serialized);
  } catch (e) {
    print("ERROR STORING EXPENSES: $e");
  }
}

class ExpenseStore extends ChangeNotifier {
  Expenses expenses = Expenses(List.empty());
  bool loading = false;
  Budget budget = Budget();
  // Reference to BudgetStore for updating budget when expenses change
  BudgetStore? _budgetStore;
  // Date range for current expenses
  DateTime? fromDate;
  DateTime? toDate;

  void setExpenses(Expenses expenses) {
    this.expenses = expenses;
    storeExpensesInStorage(expenses);

    notifyListeners();
  }

  // Initialize from app init response
  void initializeFromAppData(AppInitResponse initData) {
    print("\n------- INITIALIZING EXPENSE STORE FROM APP INIT DATA -------");

    // Update expenses
    if (initData.expenses.isNotEmpty) {
      final sortedExpenses = List<Expense>.from(initData.expenses);
      sortedExpenses.sort((a, b) => b.datetime.compareTo(a.datetime));

      expenses = Expenses(sortedExpenses);
      storeExpensesInStorage(expenses);
      print("Initialized ${expenses.list.length} expenses from app init data");
    }

    // Update date range
    fromDate = initData.dateRange.fromDate;
    toDate = initData.dateRange.toDate;
    print(
      "Date range set: ${fromDate?.toIso8601String()} to ${toDate?.toIso8601String()}",
    );

    print("------- EXPENSE STORE INITIALIZATION COMPLETE -------\n");
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
      "Replacing local expenses with ${sortedServerExpenses.length} server expenses",
    );

    // Log a few server expenses
    if (sortedServerExpenses.isNotEmpty) {
      final sampleExpenses = sortedServerExpenses
          .take(min(3, sortedServerExpenses.length))
          .map(
            (e) =>
                "ID: ${e.id}, Date: ${e.datetime.toIso8601String()}, Amount: ${e.amount}, Category: ${e.category}",
          )
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

  void deleteExpense(id, {BuildContext? context}) {
    // Find the expense before removing it
    final expenseIndex = expenses.list.indexWhere((e) => e.id == id);

    if (expenseIndex >= 0) {
      final expense = expenses.list[expenseIndex];

      // Remove the expense
      expenses.remove(id);
      storeExpensesInStorage(expenses);

      // Update budget store if context is provided
      if (context != null) {
        final budgetStore = Provider.of<BudgetStore>(context, listen: false);
        budgetStore.updateBudgetForExpenseChange(
          expense.amount,
          expense.category,
          isAddition: false,
        );
      } else if (_budgetStore != null) {
        _budgetStore!.updateBudgetForExpenseChange(
          expense.amount,
          expense.category,
          isAddition: false,
        );
      }
    }

    notifyListeners();
  }

  void updateExpense(String id, Expense newExpense, {BuildContext? context}) {
    // Find the old expense before updating
    final expenseIndex = expenses.list.indexWhere((e) => e.id == id);

    if (expenseIndex >= 0) {
      final oldExpense = expenses.list[expenseIndex];

      // Update the expense
      expenses.update(id, newExpense);
      storeExpensesInStorage(expenses);

      // Update budget store if context is provided
      if (context != null) {
        final budgetStore = Provider.of<BudgetStore>(context, listen: false);
        budgetStore.updateBudgetForExpenseChange(
          newExpense.amount,
          newExpense.category,
          isUpdate: true,
          oldAmount: oldExpense.amount,
        );
      } else if (_budgetStore != null) {
        _budgetStore!.updateBudgetForExpenseChange(
          newExpense.amount,
          newExpense.category,
          isUpdate: true,
          oldAmount: oldExpense.amount,
        );
      }
    }

    notifyListeners();
  }

  void updateBudgetAmount(String category, num newAmount) {
    budget.updateAmount(category, newAmount.toDouble());

    notifyListeners();
  }

  void add(Expense expense, {BuildContext? context}) {
    // First check if expense with this ID already exists
    var existingIndex = expenses.list.indexWhere((e) => e.id == expense.id);

    if (existingIndex != -1) {
      // Update existing expense
      Expense oldExpense = expenses.list[existingIndex];
      expenses.update(expense.id, expense);

      // Update budget store if context is provided
      if (context != null) {
        final budgetStore = Provider.of<BudgetStore>(context, listen: false);
        budgetStore.updateBudgetForExpenseChange(
          expense.amount,
          expense.category,
          isUpdate: true,
          oldAmount: oldExpense.amount,
        );
      } else if (_budgetStore != null) {
        _budgetStore!.updateBudgetForExpenseChange(
          expense.amount,
          expense.category,
          isUpdate: true,
          oldAmount: oldExpense.amount,
        );
      }
    } else {
      // Add new expense
      expenses.add(expense);

      // Update budget store if context is provided
      if (context != null) {
        final budgetStore = Provider.of<BudgetStore>(context, listen: false);
        budgetStore.updateBudgetForExpenseChange(
          expense.amount,
          expense.category,
        );
      } else if (_budgetStore != null) {
        _budgetStore!.updateBudgetForExpenseChange(
          expense.amount,
          expense.category,
        );
      }
    }

    storeExpensesInStorage(expenses);
    notifyListeners();
  }

  // Set the BudgetStore reference
  void setBudgetStore(BudgetStore budgetStore) {
    _budgetStore = budgetStore;
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
