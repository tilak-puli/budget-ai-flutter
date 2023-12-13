import 'package:budget_ai/components/expense_card.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:flutter/material.dart';

class ExpenseList extends StatelessWidget {
  final ExpenseStore expenseStore;

  const ExpenseList(this.expenseStore, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
            child: expenseStore.expenses.isEmpty
                ? const NoExpensesMessage()
                : ExpensesListBody(expenseStore),
          ),
      ],
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

    return ListView(children: transactions);
  }
}

class NoExpensesMessage extends StatelessWidget {
  const NoExpensesMessage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Text(
      'No expenses to show.\n Just message the AI to start your budgeting journey.',
      textAlign: TextAlign.center,
    );
  }
}
