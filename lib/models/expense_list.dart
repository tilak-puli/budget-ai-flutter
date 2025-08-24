import 'package:finly/models/expense.dart';
import "package:collection/collection.dart";

class Expenses {
  List<Expense> list;

  // Create a constructor that ensures the list is mutable
  Expenses(List<Expense> expenses) : list = List<Expense>.from(expenses);

  factory Expenses.fromJson(List jsonList) {
    return Expenses(jsonList.map((e) => Expense.fromJson(e)).toList());
  }

  get isEmpty => list.isEmpty;

  get total => list.map((e) => e.amount).sum;

  get groupByTime => groupBy(list, (expense) => getTimeTag(expense.datetime));

  get groupByCategory => groupBy(list, (expense) => expense.category);

  String getTimeTag(DateTime datetime) {
    var now = DateTime.now();
    if (isSameDate(datetime, now)) {
      return "Today";
    } else if (datetime.difference(now).inDays <= 1) {
      return 'Yesterday';
    } else if (isInSameWeek(datetime, now)) {
      return "This Week";
    }

    return "Older";
  }

  bool isInSameWeek(DateTime date1, DateTime date2) {
    // Check if the week number and year are the same for both dates
    return date1.weekday == date2.weekday &&
        date1.difference(startOfWeek(date1)).inDays ==
            date2.difference(startOfWeek(date2)).inDays;
  }

  DateTime startOfWeek(DateTime date) {
    // Calculate the start of the week (Sunday) for the given date
    return date.subtract(Duration(days: date.weekday - 1));
  }

  bool isSameDate(DateTime date, DateTime other) {
    return date.year == other.year &&
        date.month == other.month &&
        date.day == other.day;
  }

  void add(Expense expense) {
    list.insert(0, expense);
  }

  void remove(id) {
    list.removeWhere((element) => element.id == id);
  }

  void update(String id, Expense newExpense) {
    var index = list.indexWhere((element) => element.id == id);

    if (index != -1) {
      list[index] = newExpense;
    }
  }
}
