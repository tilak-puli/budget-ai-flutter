import 'package:budget_ai/models/expense_list.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Categories extends StatelessWidget {
  final Expenses expenses;

  const Categories(
    this.expenses, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var groupedByCategoryList = expenses.groupByCategory.entries
        .map((entry) => [entry.key, entry.value])
        .toList();
    final List<ChartData> chartData = groupedByCategoryList
        .map<ChartData>(
            (group) => ChartData(group[0], Expenses(group[1]).total))
        .toList();

    return Center(
        child: expenses.isEmpty
            ? const Center(
                child: Text("No transactions recorded this month"),
              )
            : SfCircularChart(
                tooltipBehavior: TooltipBehavior(enable: true),
                legend: const Legend(isVisible: true),
                series: <CircularSeries>[
                    // Render pie chart
                    PieSeries<ChartData, String>(
                        dataSource: chartData,
                        xValueMapper: (ChartData data, _) => data.x,
                        yValueMapper: (ChartData data, _) => data.y,
                        dataLabelSettings:
                            const DataLabelSettings(isVisible: true)),
                  ]));
  }
}

class ChartData {
  ChartData(this.x, this.y);
  final String x;
  final int y;
}
