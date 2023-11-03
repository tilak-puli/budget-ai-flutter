import 'package:budget_ai/models/expense.dart';
import 'package:flutter/material.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;

  const ExpenseCard(
    this.expense, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(children: [
          Row(
            children: [
              Text(expense.datetime.toString().split('.')[0]),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                expense.description.toString(),
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                expense.amount.toString(),
                style: const TextStyle(color: Colors.redAccent, fontSize: 18),
              ),
            ],
          ),
          Row(
            children: [
              Text(expense.category),
            ],
          ),
        ]),
      ),
    );
  }
}
