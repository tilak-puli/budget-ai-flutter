// List of available categories supported by the API
final List<String> budgetList = [
  "Food",
  "Transport",
  "Rent",
  "Entertainment",
  "Utilities",
  "Groceries",
  "Shopping",
  "Healthcare",
  "Personal Care",
  "Misc",
  "Savings",
  "Insurance",
  "Lent"
];

class Budget {
  String? id;
  double totalBudget;
  Map<String, double> categoryBudgets;

  Budget({
    this.id,
    this.totalBudget = 0.0,
    Map<String, double>? categoryBudgets,
  }) : categoryBudgets = categoryBudgets ?? {};

  // Calculate total budget as the sum of all category budgets or the overall total
  double get total {
    if (totalBudget > 0) {
      return totalBudget;
    }

    // If no total budget is explicitly set, sum the categories
    if (categoryBudgets.isNotEmpty) {
      return categoryBudgets.values.reduce((sum, amount) => sum + amount);
    }

    return 0.0;
  }

  // Get a specific category budget amount
  double getAmount(String category) {
    // Standardize category name format
    final standardCategory = category.trim();

    // First check exact match
    if (categoryBudgets.containsKey(standardCategory)) {
      return categoryBudgets[standardCategory]!;
    }

    // Then check case-insensitive
    final lowerCategory = standardCategory.toLowerCase();
    for (var key in categoryBudgets.keys) {
      if (key.toLowerCase() == lowerCategory) {
        return categoryBudgets[key]!;
      }
    }

    // Return 0 if no budget is set for this category
    return 0.0;
  }

  // Update a category budget amount
  void updateAmount(String category, double amount) {
    // Standardize category name format
    final standardCategory = category.trim();
    categoryBudgets[standardCategory] = amount;
  }

  // Factory constructor to create a Budget from API JSON response
  factory Budget.fromJson(Map<String, dynamic> json) {
    // Extract category budgets and convert to Map<String, double>
    final Map<String, dynamic> rawCategoryBudgets =
        json['categoryBudgets'] ?? {};
    final Map<String, double> categoryBudgets = {};

    rawCategoryBudgets.forEach((key, value) {
      // Ensure values are doubles
      if (value is num) {
        categoryBudgets[key] = value.toDouble();
      }
    });

    return Budget(
      id: json['_id'],
      totalBudget: (json['totalBudget'] ?? 0.0).toDouble(),
      categoryBudgets: categoryBudgets,
    );
  }

  // Convert Budget to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'totalBudget': totalBudget,
      'categoryBudgets': categoryBudgets,
      if (id != null) '_id': id,
    };
  }
}

// Budget summary model to represent monthly budget vs spending data
class BudgetSummary {
  final double totalBudget;
  final double totalSpending;
  final double remainingBudget;
  final List<CategorySummary> categories;
  final int month;
  final int year;
  final String? id;

  BudgetSummary({
    required this.totalBudget,
    required this.totalSpending,
    required this.remainingBudget,
    required this.categories,
    required this.month,
    required this.year,
    this.id,
  });

  factory BudgetSummary.fromJson(Map<String, dynamic> json) {
    final summaryData = json['summary'];

    // Parse category summaries
    final List<CategorySummary> categories = [];
    if (summaryData['categories'] != null) {
      for (var category in summaryData['categories']) {
        categories.add(CategorySummary.fromJson(category));
      }
    }

    return BudgetSummary(
      totalBudget: (summaryData['totalBudget'] ?? 0.0).toDouble(),
      totalSpending: (summaryData['totalSpending'] ?? 0.0).toDouble(),
      remainingBudget: (summaryData['remainingBudget'] ?? 0.0).toDouble(),
      categories: categories,
      month: summaryData['month'] ?? DateTime.now().month,
      year: summaryData['year'] ?? DateTime.now().year,
      id: summaryData['_id'],
    );
  }
}

// Model for category-specific budget summary
class CategorySummary {
  final String category;
  final double budget;
  final double actual;
  final double remaining;

  CategorySummary({
    required this.category,
    required this.budget,
    required this.actual,
    required this.remaining,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      category: json['category'] ?? '',
      budget: (json['budget'] ?? 0.0).toDouble(),
      actual: (json['actual'] ?? 0.0).toDouble(),
      remaining: (json['remaining'] ?? 0.0).toDouble(),
    );
  }
}
