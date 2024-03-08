import 'package:budget_ai/models/budget.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:budget_ai/utils/money.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BudgetStatus extends StatelessWidget {
  String title;

  BudgetStatus(
    this.title, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Consumer<ExpenseStore>(builder: (context, expenseStore, child) {
          return BudgetStatusCard(
              expenseStore.expenses, expenseStore.budget, title);
        })
      ],
    );
  }
}

class BudgetStatusCard extends StatelessWidget {
  final Expenses expenses;
  final Budget budget;
  final String title;

  const BudgetStatusCard(
    this.expenses,
    this.budget,
    this.title, {
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
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.normal, fontSize: 15),
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
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
              // Text(
              //   "${(total / budget.total * 100).toStringAsFixed(0)}%",
              //   style: TextStyle(color: Theme.of(context).hintColor),
              // ),
            ],
          ),
          const SizedBox(height: 5),
          // LinearProgressIndicator(
          //     backgroundColor: Theme.of(context).colorScheme.background,
          //     minHeight: 10,
          //     borderRadius: const BorderRadius.all(Radius.circular(10)),
          //     value: total / budget.total),
          // const SizedBox(height: 5),
          // Row(
          //   children: [
          //     Text("${currencyFormat.format(budget.total - total)} left of ${currencyFormat.format(budget.total)}"),
          //     IconButton(
          //         onPressed: () => showDialog<String>(
          //             context: context,
          //             builder: (BuildContext context) => Dialog(
          //                   child: Consumer<ExpenseStore>(
          //                       builder: (context, expenseStore, child) {
          //                     return BudgetEditDailog(expenseStore);
          //                   }),
          //                 )),
          //         icon: const Icon(Icons.edit))
          //   ],
          // )
        ]),
      ),
    );
  }
}

class BudgetEditDailog extends StatelessWidget {
  final ExpenseStore expenseStore;

  const BudgetEditDailog(
    this.expenseStore, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          AppBar(title: const Text("Edit Budget")),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    "Total Month Bugdet: ${currencyFormat.format(expenseStore.budget.total)}",
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                ...budgetList
                    .map((category) => BudgetInput(
                            category, expenseStore.budget.getAmount(category),
                            (newAmount) {
                          expenseStore.updateBudgetAmount(category, newAmount);
                        }))
                    .toList()
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetInput extends StatelessWidget {
  final String category;
  final void Function(int newAmount) onChange;
  final int initAmount;

  const BudgetInput(this.category, this.initAmount, this.onChange, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          category,
          style: const TextStyle(fontSize: 20),
        ),
        SizedBox(
            width: 100,
            child: TextFormField(
                keyboardType: TextInputType.number,
                initialValue: initAmount.toString(),
                onChanged: (val) {
                  onChange(int.parse(val));
                }))
      ]),
    );
  }
}
