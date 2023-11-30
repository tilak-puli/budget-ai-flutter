import 'package:budget_ai/models/expense_list.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:budget_ai/utils/money.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BudgetStatus extends StatelessWidget {
  const BudgetStatus({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Consumer<ExpenseStore>(builder: (context, expenseStore, child) {
          return BudgetStatusCard(expenseStore.expenses);
        })
      ],
    );
  }
}

class BudgetStatusCard extends StatelessWidget {
  final Expenses expenses;

  const BudgetStatusCard(this.expenses, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var total = expenses.total;
    
    return Card(
      elevation: 4,
      surfaceTintColor: Theme.of(context).colorScheme.background,
      shadowColor: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(children: [
          const Row(
            children: [
              Text(
                "This month",
                style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(total),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
              ),
              Text(
                "${(total / 25000 * 100).toStringAsFixed(0)}%",
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
              backgroundColor: Theme.of(context).colorScheme.background,
              minHeight: 10,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              value: total / 25000),
          const SizedBox(height: 5),
          Row(
            children: [
              Text("${25000 - total} left of 25,000"),
            ],
          )
        ]),
      ),
    );
  }
}
