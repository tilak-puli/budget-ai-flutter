import 'package:flutter/material.dart';

class ExpenseList extends StatelessWidget {
  const ExpenseList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 450,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No expenses to show.\n Just message the guru to start the journey.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
