class Expense {
  final String category;
  final double amount;
  final DateTime datetime;
  final String description;
  final String id;
  final String? prompt;

  const Expense(this.id, this.amount, this.category, this.description, this.datetime, this.prompt);

  factory Expense.fromJson(json) {
    return Expense(json['_id'] as String, json['amount'] as double, json['category'] as String,
        json['description'] as String, DateTime.parse(json['date']).toLocal(), json['prompt'] ?? "");
  }

  toJson() => {'_id': id, 'amount': amount, "description": description,  "category": category, 'date': datetime.toUtc().toIso8601String()};
}
