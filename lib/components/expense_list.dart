import 'package:budget_ai/components/expense_card.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:flutter/material.dart';

class ExpenseList extends StatelessWidget {
  final Expenses expenses;

  const ExpenseList(
    this.expenses, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: expenses.isEmpty
          ? const NoExpensesMessage()
          : ExpensesListBody(expenses),
    );
  }
}

class ExpensesListBody extends StatelessWidget {
  final Expenses expenses;

  const ExpensesListBody(
    this.expenses, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
      children: expenses.list.map((expense) => ExpenseCard(expense)).toList(),
    ));
  }
}

class NoExpensesMessage extends StatelessWidget {
  const NoExpensesMessage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'No expenses to show.\n Just message the guru to start the journey.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
