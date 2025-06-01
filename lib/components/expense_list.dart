import 'package:coin_master_ai/components/expense_card.dart';
import 'package:coin_master_ai/state/expense_store.dart';
import 'package:flutter/material.dart';

class ExpenseList extends StatelessWidget {
  final ExpenseStore expenseStore;

  const ExpenseList(this.expenseStore, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [Expanded(child: ExpensesListBody(expenseStore))]);
  }
}

class ExpensesListBody extends StatelessWidget {
  final ExpenseStore expenseStore;

  const ExpensesListBody(this.expenseStore, {super.key});

  @override
  Widget build(BuildContext context) {
    return expenseStore.expenses.isEmpty
        ? const Center(child: Text("No transactions recorded this month"))
        : ListView.builder(
          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
          itemCount: expenseStore.expenses.list.length,
          itemBuilder: (context, index) {
            return ExpenseCard(expenseStore.expenses.list[index]);
          },
        );
  }
}

class NoExpensesMessage extends StatelessWidget {
  const NoExpensesMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'No expenses to show.\n Just message the AI to start your budgeting journey. for example, "biryani 250"',
      textAlign: TextAlign.center,
    );
  }
}
