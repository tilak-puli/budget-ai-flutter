import 'package:budget_ai/components/expense_card.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:budget_ai/state/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExpenseList extends StatelessWidget {
  final ExpenseStore expenseStore;

  const ExpenseList(this.expenseStore, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: expenseStore.expenses.isEmpty
            ? const NoExpensesMessage()
            : ExpensesListBody(expenseStore),
      );
  }
}

class ExpensesListBody extends StatelessWidget {
  final ExpenseStore expenseStore;


  const ExpensesListBody(this.expenseStore,  {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> transactions = [];

    expenseStore.expenses.groupByTime.forEach((k, v) {
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
