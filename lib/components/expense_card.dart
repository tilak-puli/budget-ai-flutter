import 'package:budget_ai/api.dart';
import 'package:budget_ai/components/expense_form.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/state/chat_store.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:budget_ai/theme/index.dart';
import 'package:budget_ai/utils/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

// Define category colors
var categoryColors = {
  "Food": Color(0xFFE3F2FD),
  "Groceries": Color(0xFFE8F5E9),
  "Transport": Color(0xFFFFF3E0),
  "Rent": Color(0xFFE1F5FE),
  "Entertainment": Color(0xFFF3E5F5),
  "Shopping": Color(0xFFFFEBEE),
  "Misc": Color(0xFFF5F5F5),
};

var categoryIcons = {
  "Food": Icons.restaurant,
  "Groceries": Icons.shopping_basket,
  "Transport": Icons.directions_car,
  "Rent": Icons.home,
  "Entertainment": Icons.movie,
  "Shopping": Icons.shopping_cart,
  "Misc": Icons.category,
};

var categoryIconColors = {
  "Food": Color(0xFF1565C0), // Blue
  "Groceries": Color(0xFF2E7D32), // Green
  "Transport": Color(0xFFE65100), // Orange
  "Rent": Color(0xFF0288D1), // Light Blue
  "Entertainment": Color(0xFF7B1FA2), // Purple
  "Shopping": Color(0xFFC2185B), // Pink
  "Misc": Color(0xFF757575), // Grey
};

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final bool inChatMessage;

  const ExpenseCard(
    this.expense, {
    this.inChatMessage = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? NeumorphicColors.darkCardBackground
        : NeumorphicColors.lightCardBackground;
    final textColor = isDark
        ? NeumorphicColors.darkTextPrimary
        : NeumorphicColors.lightTextPrimary;
    final categoryIcon = categoryIcons[expense.category] ?? Icons.attach_money;

    return Container(
      margin: inChatMessage
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: inChatMessage
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showDialog<String>(
            context: context,
            builder: (BuildContext context) => Dialog.fullscreen(
              child: Consumer<ExpenseStore>(
                builder: (context, expenseStore, child) {
                  return Consumer<ChatStore>(
                    builder: (context, chatStore, child) {
                      return ExpenseDailog(expense, chatStore, expenseStore);
                    },
                  );
                },
              ),
            ),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 6.0),
                  margin: const EdgeInsets.only(left: 4.0),
                  decoration: BoxDecoration(
                    color:
                        categoryColors[expense.category] ?? Color(0xFFF8F8F9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        spreadRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    categoryIcons[expense.category] ?? Icons.attach_money,
                    size: inChatMessage ? 16 : 14,
                    color:
                        categoryIconColors[expense.category] ?? Colors.black54,
                  ),
                ),
                const SizedBox(width: 16),

                // Description
                Expanded(
                  child: Text(
                    expense.description.toString(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Amount
                Text(
                  currencyFormat.format(expense.amount),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? NeumorphicColors.darkPrimaryBackground
        : NeumorphicColors.lightPrimaryBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title:
            Text("Edit Expense", style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
            child: ExpenseForm(expense, updateExpense),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              NeumorphicComponents.button(
                context: context,
                width: 120,
                onPressed: () async {
                  await deleteExpense();
                  Navigator.pop(context);
                },
                color: Colors.redAccent.withOpacity(isDark ? 0.3 : 0.1),
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: isDark ? Colors.redAccent : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              NeumorphicComponents.button(
                context: context,
                width: 120,
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark
                        ? NeumorphicColors.darkTextPrimary
                        : NeumorphicColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
