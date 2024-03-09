import 'package:budget_ai/api.dart';
import 'package:budget_ai/components/expense_form.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:budget_ai/utils/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

class IconConfig {
  IconConfig(this.icon, this.color);

  IconData icon;
  Color color;
}

var iconsMap = {
  "Food": IconConfig(Icons.fastfood, Colors.green),
  "Transport": IconConfig(Icons.commute, Colors.orange),
  "Rent": IconConfig(Icons.home, Colors.blue),
  "Entertainment": IconConfig(Icons.movie, Colors.yellow),
  "Shopping": IconConfig(Icons.shopping_cart, Colors.red),
};

class ExpenseCard extends StatelessWidget {
  final Expense expense;

  const ExpenseCard(
    this.expense, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var iconConfig =
        iconsMap[expense.category] ?? IconConfig(Icons.paid, Colors.grey);

    return ListTile(
      onTap: () => showDialog<String>(
        context: context,
        builder: (BuildContext context) => Dialog.fullscreen(
          child:
              Consumer<ExpenseStore>(builder: (context, expenseStore, child) {
            return Consumer<ChatStore>(
                builder: (context, chatStore, child) {
              return ExpenseDailog(expense, chatStore, expenseStore);
            });
          }),
        ),
      ),
      leading: Icon(iconConfig.icon, color: iconConfig.color),
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

class ExpenseDailog extends StatelessWidget {
  final ExpenseStore expenseStore;
  final ChatStore chatStore;
  final Expense expense;

  late BuildContext context;

  ExpenseDailog(
    this.expense,
    this.chatStore,
    this.expenseStore, {
    super.key,
  });

  Future<void> deleteExpense() async {
    EasyLoading.show(status: 'deleting...');
    final response = await ApiService().deleteExpense(expense.id);

    if (response.statusCode != 200) {
      EasyLoading.show(status: 'Failed to delete expenses', dismissOnTap: true);
      return;
    }

    expenseStore.deleteExpense(expense.id);
    chatStore.remove(expense.id);

    EasyLoading.dismiss();
  }

  Future<void> updateExpense(Expense newExpense) async {
    EasyLoading.show(status: 'updating...');
    final response = await ApiService().updateExpense(newExpense);

    if (response.statusCode != 200) {
      EasyLoading.show(status: 'Failed to update expense', dismissOnTap: true);
      return;
    }

    expenseStore.updateExpense(expense.id, newExpense);
    chatStore.updateMessage(expense.id, ExpenseMessage(newExpense));

    EasyLoading.dismiss();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        AppBar(title: const Text("Edit Expense")),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
              child: ExpenseForm(expense, updateExpense),
            ),
            TextButton(
              onPressed: () async {
                await deleteExpense();
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}
