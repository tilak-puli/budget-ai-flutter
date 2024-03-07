import 'package:budget_ai/components/categories.dart';
import 'package:budget_ai/components/chatbox.dart';
import 'package:budget_ai/components/expense_list.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/state/expense_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BodyTabs extends StatefulWidget {
  final Future<Expense?> Function(dynamic userMessage) addExpense;

  const BodyTabs(
    this.addExpense, {
    super.key,
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
    return Expanded(
        child: Consumer<ExpenseStore>(builder: (context, expenseStore, child) {
      return Column(children: [
              TabBar(
                controller: _nestedTabController,
                tabs: const [
                  Tab(
                    text: "Chat",
                  ),
                  Tab(
                    text: "Transactions",
                  ),
                  Tab(
                    text: "Categories",
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _nestedTabController,
                  children: [
                    Chatbox(widget.addExpense),
                    ExpenseList(expenseStore),
                    Categories(expenseStore.expenses),
                  ],
                ),
              )
            ]);
    }));
  }
}
