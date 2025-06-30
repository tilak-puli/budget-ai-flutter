import 'package:finly/models/expense.dart';
import 'package:finly/models/budget.dart';

// Helper functions for parsing numeric values
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class AppInitResponse {
  final List<Expense> expenses;
  final QuotaInfo quota;
  final BudgetInfo budget;
  final BudgetSummary budgetSummary;
  final Map<String, bool> featureFlags;
  final Map<String, dynamic> config;
  final DateRange dateRange;

  AppInitResponse({
    required this.expenses,
    required this.quota,
    required this.budget,
    required this.budgetSummary,
    required this.featureFlags,
    required this.config,
    required this.dateRange,
  });

  factory AppInitResponse.fromJson(Map<String, dynamic> json) {
    return AppInitResponse(
      expenses:
          ((json['expenses'] as List?) ?? [])
              .map((e) => Expense.fromJson(e))
              .toList(),
      quota:
          json['quota'] != null
              ? QuotaInfo.fromJson(json['quota'])
              : QuotaInfo(
                hasQuotaLeft: false,
                remainingQuota: 0,
                isPremium: false,
                dailyLimit: 0,
                standardLimit: 0,
                premiumLimit: 0,
              ),
      budget:
          json['budget'] != null
              ? BudgetInfo.fromJson(json['budget'])
              : BudgetInfo(categories: [], budgetExists: false),
      budgetSummary:
          json['budgetSummary'] != null
              ? BudgetSummary.fromJson(json['budgetSummary'])
              : BudgetSummary(
                totalBudget: 0.0,
                totalSpending: 0.0,
                remainingBudget: 0.0,
                categories: [],
                month: DateTime.now().month,
                year: DateTime.now().year,
                budgetExists: false,
              ),
      featureFlags:
          (json['featureFlags'] != null)
              ? Map<String, bool>.from(json['featureFlags'])
              : {},
      config: json['config'] ?? {},
      dateRange:
          json['dateRange'] != null
              ? DateRange.fromJson(json['dateRange'])
              : DateRange(
                fromDate: DateTime.now().subtract(const Duration(days: 30)),
                toDate: DateTime.now(),
              ),
    );
  }
}

class QuotaInfo {
  final bool hasQuotaLeft;
  final int remainingQuota;
  final bool isPremium;
  final int dailyLimit;
  final int standardLimit;
  final int premiumLimit;

  QuotaInfo({
    required this.hasQuotaLeft,
    required this.remainingQuota,
    required this.isPremium,
    required this.dailyLimit,
    required this.standardLimit,
    required this.premiumLimit,
  });

  factory QuotaInfo.fromJson(Map<String, dynamic> json) {
    return QuotaInfo(
      hasQuotaLeft: json['hasQuotaLeft'] ?? false,
      remainingQuota: _parseInt(json['remainingQuota']),
      isPremium: json['isPremium'] ?? false,
      dailyLimit: _parseInt(json['dailyLimit']),
      standardLimit: _parseInt(json['standardLimit']),
      premiumLimit: _parseInt(json['premiumLimit']),
    );
  }
}

class BudgetInfo {
  final Budget? budget;
  final List<String> categories;
  final bool budgetExists;

  BudgetInfo({
    this.budget,
    required this.categories,
    required this.budgetExists,
  });

  factory BudgetInfo.fromJson(Map<String, dynamic> json) {
    return BudgetInfo(
      budget: Budget.fromJson(json['budget']),
      categories: List<String>.from(json['categories']),
      budgetExists: json['budgetExists'] ?? false,
    );
  }
}

class BudgetSummary {
  final double totalBudget;
  final double totalSpending;
  final double remainingBudget;
  final List<CategorySummary> categories;
  final int month;
  final int year;
  final bool budgetExists;

  BudgetSummary({
    required this.totalBudget,
    required this.totalSpending,
    required this.remainingBudget,
    required this.categories,
    required this.month,
    required this.year,
    required this.budgetExists,
  });

  factory BudgetSummary.fromJson(Map<String, dynamic> json) {
    return BudgetSummary(
      totalBudget: _parseDouble(json['totalBudget']),
      totalSpending: _parseDouble(json['totalSpending']),
      remainingBudget: _parseDouble(json['remainingBudget']),
      categories:
          json['categories'] != null
              ? ((json['categories'] as List?)
                      ?.map((e) => CategorySummary.fromJson(e))
                      .toList() ??
                  [])
              : [],
      month: _parseInt(json['month']),
      year: _parseInt(json['year']),
      budgetExists: json['budgetExists'] ?? false,
    );
  }
}

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
      budget: _parseDouble(json['budget']),
      actual: _parseDouble(json['actual']),
      remaining: _parseDouble(json['remaining']),
    );
  }
}

class DateRange {
  final DateTime fromDate;
  final DateTime toDate;

  DateRange({required this.fromDate, required this.toDate});

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      fromDate: DateTime.parse(json['fromDate']),
      toDate: DateTime.parse(json['toDate']),
    );
  }
}
