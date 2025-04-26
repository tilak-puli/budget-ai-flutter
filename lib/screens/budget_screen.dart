import 'package:budget_ai/models/budget.dart';
import 'package:budget_ai/state/budget_store.dart';
import 'package:budget_ai/theme/index.dart';
import 'package:budget_ai/utils/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'dart:async';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _totalBudgetController = TextEditingController();
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize budget data when the screen loads
    _initializeBudget();
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    super.dispose();
  }

  Future<void> _initializeBudget() async {
    if (!_isInitialized) {
      // No need to set loading state as we're just using in-memory data
      final budgetStore = Provider.of<BudgetStore>(context, listen: false);

      // The budget data is already loaded by the homepage, just use it
      // Just update the controller with the current budget value
      _totalBudgetController.text = budgetStore.budget.totalBudget > 0
          ? budgetStore.budget.totalBudget.toString()
          : '';

      _isInitialized = true;
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? NeumorphicColors.darkPrimaryBackground
        : NeumorphicColors.lightPrimaryBackground;
    final textColor = isDark
        ? NeumorphicColors.darkTextPrimary
        : NeumorphicColors.lightTextPrimary;
    final accentColor =
        isDark ? NeumorphicColors.darkAccent : NeumorphicColors.lightAccent;

    return Consumer<BudgetStore>(
      builder: (context, budgetStore, child) {
        // Show loading indicator while initializing
        if (_isLoading || budgetStore.loading) {
          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              title: const Text('Budget Management'),
              backgroundColor: backgroundColor,
              elevation: 0,
              actions: [
                // Add refresh button (disabled while loading)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  tooltip: 'Refreshing...',
                  onPressed: null, // Disabled while loading
                ),
              ],
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show error if any
        if (budgetStore.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorDialog(budgetStore.error!);
            budgetStore.clearError();
          });
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: const Text('Budget Management'),
            backgroundColor: backgroundColor,
            elevation: 0,
            actions: [
              // Add refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh budget data',
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    // Use the full initialization to fetch from API
                    await budgetStore.initializeBudget();

                    // Update the text field
                    _totalBudgetController.text =
                        budgetStore.budget.totalBudget > 0
                            ? budgetStore.budget.totalBudget.toString()
                            : '';
                  } catch (e) {
                    // Show error if refresh fails
                    _showErrorDialog('Failed to refresh budget data: $e');
                  } finally {
                    // Always reset loading state
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Budget Section
                  NeumorphicComponents.card(
                    context: context,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Monthly Budget',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: NeumorphicComponents.textField(
                                  context: context,
                                  controller: _totalBudgetController,
                                  hintText: 'Enter total budget amount',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  prefixIcon: Icon(
                                    Icons.attach_money,
                                    color: isDark
                                        ? NeumorphicColors.darkTextSecondary
                                        : NeumorphicColors.lightTextSecondary,
                                  ),
                                  onChanged: (value) {
                                    // Optional validation
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              NeumorphicComponents.button(
                                context: context,
                                width: 100,
                                onPressed: () async {
                                  // Validate and save the total budget
                                  if (_totalBudgetController.text.isEmpty) {
                                    _showErrorDialog(
                                        'Please enter a budget amount');
                                    return;
                                  }

                                  try {
                                    final amount = double.parse(
                                        _totalBudgetController.text);
                                    if (amount <= 0) {
                                      _showErrorDialog(
                                          'Please enter a valid amount greater than zero');
                                      return;
                                    }

                                    await budgetStore.setTotalBudget(amount);
                                  } catch (e) {
                                    _showErrorDialog(
                                        'Please enter a valid number');
                                  }
                                },
                                child: Text(
                                  'Save',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (budgetStore.budget.totalBudget > 0) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Current Total: ${currencyFormat.format(budgetStore.budget.totalBudget)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Category Budgets Section
                  NeumorphicComponents.card(
                    context: context,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Category Budgets',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle,
                                  color: accentColor,
                                ),
                                onPressed: () {
                                  _showAddCategoryBudgetDialog(
                                      context, budgetStore);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Show existing category budgets
                          if (budgetStore.budget.categoryBudgets.isEmpty)
                            Text(
                              'No category budgets set. Tap the + button to add a category budget.',
                              style: TextStyle(
                                color: isDark
                                    ? NeumorphicColors.darkTextSecondary
                                    : NeumorphicColors.lightTextSecondary,
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  budgetStore.budget.categoryBudgets.length,
                              itemBuilder: (context, index) {
                                final category = budgetStore
                                    .budget.categoryBudgets.keys
                                    .elementAt(index);
                                final amount = budgetStore
                                    .budget.categoryBudgets[category]!;

                                return CategoryBudgetItem(
                                  category: category,
                                  amount: amount,
                                  onEdit: () => _showEditCategoryBudgetDialog(
                                      context, budgetStore, category, amount),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Budget Summary Section (if available)
                  if (budgetStore.budgetSummary != null)
                    NeumorphicComponents.card(
                      context: context,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Budget Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Summary data
                            BudgetSummaryWidget(
                                summary: budgetStore.budgetSummary!),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Dialog to add a new category budget
  void _showAddCategoryBudgetDialog(
      BuildContext context, BudgetStore budgetStore) {
    final TextEditingController amountController = TextEditingController();
    String selectedCategory = budgetStore.categories.first;

    // Filter out categories that already have a budget
    final availableCategories = budgetStore.categories
        .where((c) => !budgetStore.budget.categoryBudgets.containsKey(c))
        .toList();

    if (availableCategories.isEmpty) {
      _showErrorDialog('All categories already have budgets assigned.');
      return;
    }

    selectedCategory = availableCategories.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Category Budget'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category dropdown
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedCategory = newValue;
                      });
                    }
                  },
                  items: availableCategories
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Amount field
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Budget Amount',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Validate and save
                  if (amountController.text.isEmpty) {
                    _showErrorDialog('Please enter a budget amount');
                    return;
                  }

                  try {
                    final amount = double.parse(amountController.text);
                    if (amount <= 0) {
                      _showErrorDialog(
                          'Please enter a valid amount greater than zero');
                      return;
                    }

                    Navigator.pop(context);
                    await budgetStore.setCategoryBudget(
                        selectedCategory, amount);
                  } catch (e) {
                    _showErrorDialog('Please enter a valid number');
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    ).then((_) {
      amountController.dispose();
    });
  }

  // Dialog to edit an existing category budget
  void _showEditCategoryBudgetDialog(BuildContext context,
      BudgetStore budgetStore, String category, double currentAmount) {
    final TextEditingController amountController =
        TextEditingController(text: currentAmount.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $category Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amount field
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Budget Amount',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Remove this category budget
                Navigator.pop(context);

                // Create a copy of existing budgets without this category
                final updatedBudgets =
                    Map<String, double>.from(budgetStore.budget.categoryBudgets)
                      ..remove(category);

                await budgetStore.setMultipleCategoryBudgets(updatedBudgets);
              },
              child: const Text('Remove'),
            ),
            TextButton(
              onPressed: () async {
                // Validate and save
                if (amountController.text.isEmpty) {
                  _showErrorDialog('Please enter a budget amount');
                  return;
                }

                try {
                  final amount = double.parse(amountController.text);
                  if (amount <= 0) {
                    _showErrorDialog(
                        'Please enter a valid amount greater than zero');
                    return;
                  }

                  Navigator.pop(context);
                  await budgetStore.setCategoryBudget(category, amount);
                } catch (e) {
                  _showErrorDialog('Please enter a valid number');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) {
      amountController.dispose();
    });
  }
}

class CategoryBudgetItem extends StatefulWidget {
  final String category;
  final double amount;
  final VoidCallback onEdit;

  const CategoryBudgetItem({
    Key? key,
    required this.category,
    required this.amount,
    required this.onEdit,
  }) : super(key: key);

  @override
  State<CategoryBudgetItem> createState() => _CategoryBudgetItemState();
}

class _CategoryBudgetItemState extends State<CategoryBudgetItem> {
  late TextEditingController _amountController;
  Timer? _debounceTimer;
  bool _isEditing = false;
  late double _displayAmount;

  @override
  void initState() {
    super.initState();
    _displayAmount = widget.amount;
    _amountController = TextEditingController(text: _displayAmount.toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CategoryBudgetItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Make sure to update the controller when the amount changes from outside
    if (oldWidget.amount != widget.amount && !_isEditing) {
      setState(() {
        _displayAmount = widget.amount;
        _amountController.text = _displayAmount.toString();
      });
    }
  }

  void _updateBudget(String value) {
    if (value.isEmpty) return;

    try {
      final newAmount = double.parse(value);
      if (newAmount != _displayAmount) {
        // Optimistically update the local state
        setState(() {
          _displayAmount = newAmount;
        });

        // Cancel existing timer if any
        _debounceTimer?.cancel();

        // Update the actual budget via BudgetStore
        final budgetStore = Provider.of<BudgetStore>(context, listen: false);
        budgetStore.setCategoryBudgetOptimistic(widget.category, newAmount);
      }
    } catch (e) {
      // Reset to previous value on parsing error
      _amountController.text = _displayAmount.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final backgroundColor = isDark
        ? NeumorphicColors.darkCardBackground.withOpacity(0.3)
        : NeumorphicColors.lightCardBackground.withOpacity(0.3);

    return Card(
      elevation: 0,
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Category icon based on name
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getCategoryColor(widget.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(widget.category),
                color: _getCategoryColor(widget.category),
              ),
            ),
            const SizedBox(width: 16),

            // Category name
            Expanded(
              flex: 2,
              child: Text(
                widget.category,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),

            // Budget amount input field
            Expanded(
              flex: 1,
              child: IntrinsicWidth(
                child: Focus(
                  onFocusChange: (hasFocus) {
                    // When focus is lost (blur event), update the budget
                    if (!hasFocus && _isEditing) {
                      _updateBudget(_amountController.text);
                      setState(() {
                        _isEditing = false;
                      });
                    }
                  },
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1,
                        ),
                      ),
                      prefixText: '₹',
                      prefixStyle: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    onEditingComplete: () {
                      setState(() {
                        _isEditing = false;
                      });
                      _updateBudget(_amountController.text);
                      FocusScope.of(context).unfocus();
                    },
                    onSubmitted: (value) {
                      setState(() {
                        _isEditing = false;
                      });
                      _updateBudget(value);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to get category color
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'rent':
        return Colors.red;
      case 'entertainment':
        return Colors.purple;
      case 'utilities':
        return Colors.teal;
      case 'groceries':
        return Colors.green;
      case 'shopping':
        return Colors.pink;
      case 'healthcare':
        return Colors.indigo;
      case 'personal care':
        return Colors.amber;
      case 'misc':
        return Colors.grey;
      case 'savings':
        return Colors.lightBlue;
      case 'insurance':
        return Colors.brown;
      case 'lent':
        return Colors.deepOrange;
      default:
        return Colors.blueGrey;
    }
  }

  // Helper to get category icon
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'rent':
        return Icons.home;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.power;
      case 'groceries':
        return Icons.shopping_basket;
      case 'shopping':
        return Icons.shopping_bag;
      case 'healthcare':
        return Icons.healing;
      case 'personal care':
        return Icons.spa;
      case 'misc':
        return Icons.category;
      case 'savings':
        return Icons.savings;
      case 'insurance':
        return Icons.security;
      case 'lent':
        return Icons.handshake;
      default:
        return Icons.attach_money;
    }
  }
}

// Widget to display budget summary
class BudgetSummaryWidget extends StatelessWidget {
  final BudgetSummary summary;

  const BudgetSummaryWidget({
    Key? key,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? NeumorphicColors.darkAccent : NeumorphicColors.lightAccent;

    // Calculate percentage
    final progressPercentage = summary.totalBudget > 0
        ? (summary.totalSpending / summary.totalBudget).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month and year
        Text(
          'Summary for ${_getMonthName(summary.month)} ${summary.year}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark
                ? NeumorphicColors.darkTextSecondary
                : NeumorphicColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Total budget vs spending
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Budget:'),
            Text(
              currencyFormat.format(summary.totalBudget),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Spent:'),
            Text(
              currencyFormat.format(summary.totalSpending),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: summary.totalSpending > summary.totalBudget
                    ? Colors.red
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Remaining:'),
            Text(
              currencyFormat.format(summary.remainingBudget),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: summary.remainingBudget < 0 ? Colors.red : accentColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Progress bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Budget Used'),
                Text(
                  '${(progressPercentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            NeumorphicComponents.progressBar(
              context: context,
              value: progressPercentage,
              progressColor:
                  progressPercentage >= 1.0 ? Colors.red : accentColor,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Category breakdown
        const Text(
          'Category Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // List of categories
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: summary.categories.length,
          itemBuilder: (context, index) {
            final category = summary.categories[index];
            return CategorySummaryItem(category: category);
          },
        ),
      ],
    );
  }

  // Helper to get month name
  String _getMonthName(int month) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1]; // Month is 1-based
  }
}

// Widget to display a category summary item
class CategorySummaryItem extends StatelessWidget {
  final CategorySummary category;

  const CategorySummaryItem({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate percentage
    final progressPercentage = category.budget > 0
        ? (category.actual / category.budget).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.category,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '${currencyFormat.format(category.actual)} / ${currencyFormat.format(category.budget)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? NeumorphicColors.darkTextSecondary
                      : NeumorphicColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progressPercentage,
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation(
              progressPercentage >= 1.0 ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
