import 'package:coin_master_ai/models/expense_list.dart';
import 'package:coin_master_ai/theme/index.dart';
import 'package:coin_master_ai/utils/money.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class Categories extends StatefulWidget {
  final Expenses expenses;

  const Categories(this.expenses, {super.key});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories>
    with SingleTickerProviderStateMixin {
  String? _selectedCategory;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Define category colors
  final Map<String, Color> categoryColors = {
    "Food": const Color(0xFFE57373),
    "Groceries": const Color(0xFF4FC3F7),
    "Transport": const Color(0xFFFFB74D),
    "Rent": const Color(0xFF9575CD),
    "Entertainment": const Color(0xFF4DB6AC),
    "Shopping": const Color(0xFFFFCC80),
    "Misc": const Color(0xFF90A4AE),
  };

  final Map<String, IconData> categoryIcons = {
    "Food": Icons.restaurant,
    "Groceries": Icons.shopping_basket,
    "Transport": Icons.directions_car,
    "Rent": Icons.home,
    "Entertainment": Icons.movie,
    "Shopping": Icons.shopping_cart,
    "Misc": Icons.category,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? NeumorphicColors.darkTextPrimary
        : NeumorphicColors.lightTextPrimary;
    final secondaryTextColor = isDark
        ? NeumorphicColors.darkTextSecondary
        : NeumorphicColors.lightTextSecondary;
    final cardBgColor = isDark
        ? NeumorphicColors.darkCardBackground
        : NeumorphicColors.lightCardBackground;

    if (widget.expenses.isEmpty) {
      return const Center(
        child: Text("No transactions recorded this month"),
      );
    }

    var groupedByCategoryMap = widget.expenses.groupByCategory;
    var categoryTotals = <String, double>{};
    var categoryPercentages = <String, double>{};

    // Calculate totals and percentages for each category
    double grandTotal = widget.expenses.total.toDouble();

    for (var entry in groupedByCategoryMap.entries) {
      double categoryTotal = Expenses(entry.value).total.toDouble();
      categoryTotals[entry.key] = categoryTotal;
      categoryPercentages[entry.key] = (categoryTotal / grandTotal) * 100;
    }

    // Sort categories by amount (descending)
    var sortedCategories = categoryTotals.keys.toList()
      ..sort((a, b) => categoryTotals[b]!.compareTo(categoryTotals[a]!));

    // Create chart data
    List<ChartData> chartData = [];
    for (var category in sortedCategories) {
      final color = categoryColors[category] ??
          Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
              .withOpacity(1.0);

      chartData.add(ChartData(
        category,
        categoryTotals[category]!,
        color,
      ));
    }

    return Column(
      children: [
        // Category selection chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = null;
                        _animationController.reset();
                        _animationController.forward();
                      });
                    },
                    backgroundColor: cardBgColor,
                    selectedColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                ...sortedCategories.map((category) {
                  final icon = categoryIcons[category] ?? Icons.circle;
                  final color = categoryColors[category] ?? Colors.grey;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      avatar: Icon(icon, size: 16, color: color),
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory =
                              category == _selectedCategory ? null : category;
                          _animationController.reset();
                          _animationController.forward();
                        });
                      },
                      backgroundColor: cardBgColor,
                      selectedColor: color.withOpacity(0.2),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),

        // Main content with pie chart and details
        Expanded(
          child: _selectedCategory == null
              ? _buildPieChartView(chartData, context, sortedCategories,
                  categoryTotals, categoryPercentages)
              : _buildCategoryDetailView(_selectedCategory!,
                  groupedByCategoryMap, categoryTotals, categoryPercentages),
        ),
      ],
    );
  }

  Widget _buildPieChartView(
      List<ChartData> chartData,
      BuildContext context,
      List<String> sortedCategories,
      Map<String, double> categoryTotals,
      Map<String, double> categoryPercentages) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? NeumorphicColors.darkTextPrimary
        : NeumorphicColors.lightTextPrimary;

    return Column(
      children: [
        // Pie chart
        Expanded(
          flex: 3,
          child: FadeTransition(
            opacity: _animation,
            child: SfCircularChart(
                margin: EdgeInsets.zero,
                legend: Legend(
                  isVisible: false, // We'll build our own legend
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x: \${point.y}',
                  color: isDark ? Colors.grey[800] : Colors.white,
                  textStyle:
                      TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                series: <CircularSeries>[
                  // Render pie chart with smooth animation
                  PieSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    pointColorMapper: (ChartData data, _) => data.color,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      textStyle: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      useSeriesColor: true,
                      labelIntersectAction: LabelIntersectAction.shift,
                    ),
                    enableTooltip: true,
                    animationDuration: 800,
                    explode: true,
                    explodeGesture: ActivationMode.singleTap,
                    onPointTap: (ChartPointDetails details) {
                      if (details.pointIndex != null &&
                          details.pointIndex! < sortedCategories.length) {
                        setState(() {
                          _selectedCategory =
                              sortedCategories[details.pointIndex!];
                          _animationController.reset();
                          _animationController.forward();
                        });
                      }
                    },
                  ),
                ]),
          ),
        ),

        // Category breakdown list
        Expanded(
          flex: 2,
          child: ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: sortedCategories.length,
            itemBuilder: (context, index) {
              final category = sortedCategories[index];
              final total = categoryTotals[category]!;
              final percentage = categoryPercentages[category]!;
              final color = categoryColors[category] ?? Colors.grey;
              final icon = categoryIcons[category] ?? Icons.circle;

              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      index / sortedCategories.length * 0.6,
                      (index + 1) / sortedCategories.length * 0.6 + 0.4,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(category),
                  subtitle: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(total),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                      _animationController.reset();
                      _animationController.forward();
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDetailView(
      String category,
      Map<String, List<dynamic>> groupedByCategoryMap,
      Map<String, double> categoryTotals,
      Map<String, double> categoryPercentages) {
    final expenses = groupedByCategoryMap[category] ?? [];
    final total = categoryTotals[category] ?? 0.0;
    final percentage = categoryPercentages[category] ?? 0.0;
    final color = categoryColors[category] ?? Colors.grey;
    final icon = categoryIcons[category] ?? Icons.circle;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group by day for the time series
    final expensesByDay = <DateTime, double>{};
    for (var expense in expenses) {
      final date = DateTime(
        expense.datetime.year,
        expense.datetime.month,
        expense.datetime.day,
      );

      expensesByDay.update(
        date,
        (value) => value + expense.amount.toDouble(),
        ifAbsent: () => expense.amount.toDouble(),
      );
    }

    // Sort days and create chart data
    final sortedDays = expensesByDay.keys.toList()..sort();
    final timeSeriesData = sortedDays.map((date) {
      return TimeSeriesData(date, expensesByDay[date]!);
    }).toList();

    return Column(
      children: [
        // Category header
        Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}% of total spending',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Total spent',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Time series chart for the category
        if (timeSeriesData.isNotEmpty)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FadeTransition(
                opacity: _animation,
                child: SfCartesianChart(
                  primaryXAxis: DateTimeAxis(
                    intervalType: DateTimeIntervalType.days,
                    dateFormat: DateFormat.MMMd(),
                    majorGridLines: const MajorGridLines(width: 0),
                  ),
                  primaryYAxis: NumericAxis(
                    numberFormat: NumberFormat.compactCurrency(symbol: '\$'),
                    axisLine: const AxisLine(width: 0),
                    majorTickLines: const MajorTickLines(size: 0),
                  ),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  series: <CartesianSeries<TimeSeriesData, DateTime>>[
                    SplineAreaSeries<TimeSeriesData, DateTime>(
                      dataSource: timeSeriesData,
                      xValueMapper: (TimeSeriesData data, _) => data.date,
                      yValueMapper: (TimeSeriesData data, _) => data.amount,
                      name: category,
                      color: color.withOpacity(0.6),
                      borderColor: color,
                      borderWidth: 2,
                      animationDuration: 800,
                    )
                  ],
                ),
              ),
            ),
          ),

        // Transaction list for the category
        Expanded(
          flex: 3,
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];

              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      0.3 + index / expenses.length * 0.5,
                      0.3 + (index + 1) / expenses.length * 0.5,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  decoration: NeumorphicBox.cardDecoration(
                    context: context,
                    color: isDark
                        ? NeumorphicColors.darkCardBackground
                        : NeumorphicColors.lightCardBackground,
                    borderRadius: 12.0,
                    depth: 3.0,
                  ),
                  child: ListTile(
                    title: Text(expense.description),
                    subtitle: Text(
                      _formatDate(expense.datetime),
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      currencyFormat.format(expense.amount),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class ChartData {
  final String x;
  final double y;
  final Color color;

  ChartData(this.x, this.y, this.color);
}

class TimeSeriesData {
  final DateTime date;
  final double amount;

  TimeSeriesData(this.date, this.amount);
}
