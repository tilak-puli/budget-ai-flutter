import 'package:finly/api.dart';
import 'package:finly/components/expense_form.dart';
import 'package:finly/models/expense.dart';
import 'package:finly/state/chat_store.dart';
import 'package:finly/state/expense_store.dart';
import 'package:finly/theme/index.dart';
import 'package:finly/utils/money.dart';
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

  const ExpenseCard(this.expense, {this.inChatMessage = false, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark
            ? NeumorphicColors.darkCardBackground
            : NeumorphicColors.lightCardBackground;
    final textColor =
        isDark
            ? NeumorphicColors.darkTextPrimary
            : NeumorphicColors.lightTextPrimary;
    final categoryIcon = categoryIcons[expense.category] ?? Icons.attach_money;

    return Container(
      margin:
          inChatMessage
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      decoration:
          inChatMessage
              ? BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              )
              : NeumorphicBox.cardDecoration(
                context: context,
                color: backgroundColor,
                borderRadius: 12.0,
                depth: 4.0,
              ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              () => showDialog<String>(
                context: context,
                builder:
                    (BuildContext context) => Dialog.fullscreen(
                      child: Consumer<ExpenseStore>(
                        builder: (context, expenseStore, child) {
                          return Consumer<ChatStore>(
                            builder: (context, chatStore, child) {
                              return ExpenseDailog(
                                expense,
                                chatStore,
                                expenseStore,
                              );
                            },
                          );
                        },
                      ),
                    ),
              ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 6.0,
                  ),
                  margin: const EdgeInsets.only(left: 4.0),
                  decoration: NeumorphicBox.insetDecoration(
                    context: context,
                    color:
                        categoryColors[expense.category] ?? Color(0xFFF8F8F9),
                    borderRadius: 16.0,
                    depth: 1.5,
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
  final GlobalKey<ExpenseFormState> _expenseFormKey =
      GlobalKey<ExpenseFormState>();

  late BuildContext context;

  ExpenseDailog(this.expense, this.chatStore, this.expenseStore, {super.key});

  Future<void> deleteExpense() async {
    EasyLoading.show(status: 'deleting...');
    final response = await ApiService().deleteExpense(expense.id);

    if (response.statusCode != 200) {
      EasyLoading.show(status: 'Failed to delete expenses', dismissOnTap: true);
      return;
    }

    expenseStore.deleteExpense(expense.id, context: this.context);
    chatStore.remove(expense.id);

    EasyLoading.dismiss();
    Navigator.pop(context);
  }

  Future<void> updateExpense(Expense newExpense) async {
    EasyLoading.show(status: 'updating...');
    final response = await ApiService().updateExpense(newExpense);

    if (response.statusCode != 200) {
      EasyLoading.show(status: 'Failed to update expense', dismissOnTap: true);
      return;
    }

    expenseStore.updateExpense(expense.id, newExpense, context: this.context);
    chatStore.updateMessage(expense.id, ExpenseMessage(newExpense));

    EasyLoading.dismiss();
    Navigator.pop(context);
  }

  void saveAndSubmitForm() {
    final formState = _expenseFormKey.currentState;
    if (formState != null && formState.validate()) {
      formState.save();
      formState.submitForm(updateExpense);
    }
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark
            ? NeumorphicColors.darkPrimaryBackground
            : NeumorphicColors.lightPrimaryBackground;
    final textColor =
        isDark
            ? NeumorphicColors.darkTextPrimary
            : NeumorphicColors.lightTextPrimary;
    final accentColor =
        isDark ? NeumorphicColors.darkAccent : NeumorphicColors.lightAccent;
    final destructiveColor = Colors.redAccent.shade200;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Edit Expense",
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor:
                        isDark
                            ? NeumorphicColors.darkCardBackground
                            : NeumorphicColors.lightCardBackground,
                    title: Text(
                      'Delete Expense',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to delete this expense?',
                      style: TextStyle(color: textColor),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          deleteExpense();
                        },
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: destructiveColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(Icons.delete_outline, color: destructiveColor),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Form
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ExpenseForm(
                    expense,
                    updateExpense,
                    key: _expenseFormKey,
                  ),
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? NeumorphicColors.darkCardBackground.withOpacity(0.7)
                        : NeumorphicColors.lightCardBackground.withOpacity(0.7),
                border: Border(
                  top: BorderSide(
                    color:
                        isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cancel button
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: textColor,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Update button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saveAndSubmitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Update',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
