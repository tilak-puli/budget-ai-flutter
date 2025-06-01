import 'package:coin_master_ai/models/budget.dart';
import 'package:coin_master_ai/models/expense_list.dart';
import 'package:coin_master_ai/state/expense_store.dart';
import 'package:coin_master_ai/theme/index.dart';
import 'package:coin_master_ai/utils/money.dart';
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
    return Consumer<ExpenseStore>(builder: (context, expenseStore, child) {
      return BudgetStatusCard(
          expenseStore.expenses, expenseStore.budget, title);
    });
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

    // Calculate budget percentage if budget has a valid total
    double percentUsed = 0.0;
    if (budget.total > 0) {
      percentUsed = (total / budget.total).clamp(0.0, 1.0);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? NeumorphicColors.darkTextPrimary
        : NeumorphicColors.lightTextPrimary;
    final secondaryTextColor = isDark
        ? NeumorphicColors.darkTextSecondary
        : NeumorphicColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
              GestureDetector(
                onTap: () => showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Consumer<ExpenseStore>(
                      builder: (context, expenseStore, child) {
                        return BudgetEditDailog(expenseStore);
                      },
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Amount display
          Text(
            currencyFormat.format(total),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 20),

          // Modernized progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Monthly Budget",
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                  Text(
                    "${(percentUsed * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentUsed,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isDark
                              ? NeumorphicColors.darkAccent
                              : NeumorphicColors.lightAccent,
                          isDark
                              ? NeumorphicColors.darkSecondaryAccent
                              : NeumorphicColors.lightSecondaryAccent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Budget remaining text
          if (budget.total > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Remaining",
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                Text(
                  currencyFormat.format(budget.total - total),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? NeumorphicColors.darkAccent
                        : NeumorphicColors.lightAccent,
                  ),
                ),
              ],
            ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? NeumorphicColors.darkPrimaryBackground
        : NeumorphicColors.lightPrimaryBackground;

    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            AppBar(
              title: Text("Edit Budget",
                  style: Theme.of(context).textTheme.titleLarge),
              backgroundColor: backgroundColor,
              elevation: 0,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  NeumorphicComponents.card(
                    context: context,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Total Month Budget: ${currencyFormat.format(expenseStore.budget.total)}",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...budgetList
                      .map((category) => BudgetInput(
                              category, expenseStore.budget.getAmount(category),
                              (newAmount) {
                            expenseStore.updateBudgetAmount(
                                category, newAmount);
                          }))
                      .toList(),
                  const SizedBox(height: 16),
                  NeumorphicComponents.button(
                    context: context,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: isDark
                            ? NeumorphicColors.darkAccent
                            : NeumorphicColors.lightAccent,
                        fontWeight: FontWeight.w500,
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

class BudgetInput extends StatelessWidget {
  final String category;
  final void Function(num newAmount) onChange;
  final num initAmount;

  const BudgetInput(this.category, this.initAmount, this.onChange, {super.key});

  @override
  Widget build(BuildContext context) {
    print(
        "DEBUG: BudgetInput for category: $category, initAmount: $initAmount (type: ${initAmount.runtimeType})");

    final controller = TextEditingController(text: initAmount.toString());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: NeumorphicComponents.categoryBadge(
            context: context,
            text: category,
            borderRadius: 12.0,
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 120,
          child: NeumorphicComponents.textField(
            context: context,
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: (val) {
              // Try to parse as int first, if fails then parse as double
              try {
                onChange(int.parse(val));
              } catch (e) {
                try {
                  onChange(double.parse(val));
                } catch (e) {
                  // If all parsing fails, default to 0
                  onChange(0);
                }
              }
            },
          ),
        ),
      ]),
    );
  }
}
