class Expense {
  final String category;
  final int amount;
  final DateTime datetime;
  final String description;
  final String id;

  const Expense(this.id, this.amount, this.category, this.description, this.datetime);

  factory Expense.fromJson(json) {
    return Expense(json['_id'] as String, json['amount'] as int, json['category'] as String,
        json['description'] as String, DateTime.parse(json['date']));
  }

  toJson() => {'_id': id, 'amount': amount, "description": description,  "category": category, 'date': datetime.toIso8601String()};
}
