class Expense {
  final String category;
  final int amount;
  final DateTime datetime;
  final String description;

  const Expense(this.amount, this.category, this.description, this.datetime);

  factory Expense.fromJson(json) {
    return Expense(json['amount'] as int, json['category'] as String,
        json['description'] as String, DateTime.parse(json['date']));
  }
}
