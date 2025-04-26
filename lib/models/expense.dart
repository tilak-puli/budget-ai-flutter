import 'package:uuid/uuid.dart';

class Expense {
  final String category;
  final num amount;
  final DateTime datetime;
  final String description;
  final String id;
  final String? prompt;

  const Expense(this.id, this.amount, this.category, this.description,
      this.datetime, this.prompt);

  factory Expense.fromJson(dynamic json) {

    // Handle both direct response and nested response formats
    final Map<String, dynamic> data = json is Map<String, dynamic> ? json : {};

    // If the response has an "expense" field, use that
    final Map<String, dynamic> expenseData =
        data.containsKey('expense') ? data['expense'] : data;

    // Get ID - handle different field names
    String id; 
    if (expenseData['_id'] is Map) {
      // If _id is an object (empty or not), generate a new UUID
      id = const Uuid().v4();
    } else {
      id =
          expenseData['_id']?.toString() ?? expenseData['id']?.toString() ?? '';
    }

    // Get other fields with null safety
    final num amount = expenseData['amount'] as num? ?? 0;
    final String category = expenseData['category'] as String? ?? 'Other';
    final String description = expenseData['description'] as String? ?? '';

    // Handle different date field names and formats
    String? dateStr = expenseData['date'];
    if (dateStr == null && expenseData.containsKey('datetime')) {
      dateStr = expenseData['datetime'];
    }

    final DateTime date =
        dateStr != null ? DateTime.parse(dateStr).toLocal() : DateTime.now();

    // Get prompt or use default
    final String prompt = expenseData['prompt'] as String? ?? "Manually added";

    return Expense(id, amount, category, description, date, prompt);
  }

  toJson() => {
        '_id': id,
        'amount': amount,
        "description": description,
        "category": category,
        'date': datetime.toUtc().toIso8601String(),
        "prompt": prompt
      };
}
