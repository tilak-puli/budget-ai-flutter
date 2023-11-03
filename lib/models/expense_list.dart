import 'package:budget_ai/models/expense.dart';

class Expenses {
  final List<Expense> list;

  const Expenses(this.list);

  factory Expenses.fromJson(List jsonList) {
    return Expenses(jsonList.map((e) => Expense.fromJson(e)).toList());
  }

  get isEmpty => list.isEmpty;
}
