
DateTime getMonthStart(DateTime date) {
  return  DateTime(date.year, date.month, 1);
}


DateTime getMonthEnd(DateTime date) {
  return DateTime(date.year, date.month + 1, 0);
}
