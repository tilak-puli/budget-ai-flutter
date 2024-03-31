DateTime getMonthStart(DateTime date) {
  return  DateTime(date.year, date.month, 1);
}


DateTime getMonthEnd(DateTime date) {
  return DateTime(date.year, date.month + 1, 0, 24);
}

var today = DateTime.now();

var allowedStartDateTime = DateTime(2022);
var allowedToDateTime = DateTime(today.year + 1);