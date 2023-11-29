import 'package:budget_ai/models/expense.dart';
import "package:collection/collection.dart";

class Expenses {
  final List<Expense> list;

  const Expenses(this.list);

  factory Expenses.fromJson(List jsonList) {
    return Expenses(jsonList.map((e) => Expense.fromJson(e)).toList());
  }

  get isEmpty => list.isEmpty;

  get total =>
      list.map((e) => e.amount).reduce((value, amount) => value + amount);

  get groupByTime => groupBy(list, (expense) => getTimeTag(expense.datetime));
  
  get groupByCategory => groupBy(list, (expense) => expense.category);

  String getTimeTag(DateTime datetime) {
    var now = DateTime.now();
    if (isSameDate(datetime, now)) {
      return "Today";
    } else if(datetime.difference(now).inDays == 1) {
    } else if(datetime.difference(now).inDays <= 7 ) {
      return "Last Week";
    }

    return "Older";
  }

  bool isSameDate(DateTime date, DateTime other) {
    return date.year == other.year &&
        date.month == other.month &&
        date.day == other.day;
  }
}
