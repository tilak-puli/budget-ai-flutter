import 'package:budget_ai/models/expense_list.dart';
import 'package:flutter/material.dart';

class BudgetStatus extends StatelessWidget {
  final Expenses expenses;

  const BudgetStatus(
    this.expenses, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(children: [
              const Row(
                children: [
                  Text(
                    "This month",
                    style:
                        TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    "${expenses.total}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 25),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                  backgroundColor: Theme.of(context).colorScheme.background,
                  minHeight: 10,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  value: 0.5),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text("${25000 - expenses.total} left of 25,000"),
                ],
              )
            ]),
          ),
        ),
      ],
    );
  }
}
