import 'package:budget_ai/components/expense_card.dart';
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
    List<Widget> transactions = [];

    expenses.groupByTime.forEach((k, v) {
      transactions.add(const SizedBox(height: 10));
      transactions.add(Center(child: Text(k)));
      v.forEach((expense) => transactions.add(ExpenseCard(expense)));
    });

    return Expanded(
      child: ListView(children: transactions),
    );
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
