import 'package:coin_master_ai/components/categories.dart';
import 'package:coin_master_ai/components/chatbox.dart';
import 'package:coin_master_ai/components/expense_list.dart';
import 'package:coin_master_ai/models/expense.dart';
import 'package:coin_master_ai/state/expense_store.dart';
import 'package:coin_master_ai/theme/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BodyTabs extends StatefulWidget {
  final Future<Expense?> Function(dynamic userMessage) addExpense;
  final Map<String, dynamic>? quotaData;

  const BodyTabs(
    this.addExpense, {
    super.key,
    this.quotaData,
  });

  @override
  State<BodyTabs> createState() => _BodyTabsState();
}

class _BodyTabsState extends State<BodyTabs> with TickerProviderStateMixin {
  late TabController _nestedTabController;

  @override
  void initState() {
    super.initState();

    _nestedTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _nestedTabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? NeumorphicColors.darkAccent : NeumorphicColors.lightAccent;

    return Expanded(
      child: Consumer<ExpenseStore>(
        builder: (context, expenseStore, child) {
          return Column(
            children: [
              // Improved tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TabBar(
                  controller: _nestedTabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: accentColor,
                  unselectedLabelColor: isDark
                      ? NeumorphicColors.darkTextSecondary
                      : NeumorphicColors.lightTextSecondary,
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 3.0,
                      color: accentColor,
                    ),
                    insets: const EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  tabs: const [
                    Tab(
                      text: "Chat",
                      height: 40,
                    ),
                    Tab(
                      text: "Transactions",
                      height: 40,
                    ),
                    Tab(
                      text: "Categories",
                      height: 40,
                    ),
                  ],
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _nestedTabController,
                  children: [
                    Chatbox(widget.addExpense, quotaData: widget.quotaData),
                    ExpenseList(expenseStore),
                    Categories(expenseStore.expenses),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
