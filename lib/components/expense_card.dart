import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/utils/money.dart';
import 'package:flutter/material.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;

  const ExpenseCard(
    this.expense, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.map),
      title: Text(
        expense.description.toString(),
        style: const TextStyle(fontSize: 18),
      ),
      trailing: Text(
        currencyFormat.format(expense.amount),
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}
