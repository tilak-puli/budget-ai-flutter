import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/utils/money.dart';
import 'package:flutter/material.dart';

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
    var iconConfig = iconsMap[expense.category] ?? IconConfig(Icons.paid, Colors.grey);

    return ListTile(
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
