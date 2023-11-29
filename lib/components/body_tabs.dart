import 'package:budget_ai/components/categories.dart';
import 'package:budget_ai/components/expense_list.dart';
import 'package:budget_ai/models/expense_list.dart';
import 'package:flutter/material.dart';

class BodyTabs extends StatefulWidget {
  final Expenses expenses;

  const BodyTabs(
    this.expenses, {
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

    _nestedTabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _nestedTabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          TabBar(
            controller: _nestedTabController,
            tabs: const [
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
                ExpenseList(widget.expenses),
                Categories(widget.expenses),
              ],
            ),
          )
        ],
      ),
    );
  }
}