import 'package:budget_ai/utils/time.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'dart:developer';

var monthFormat = DateFormat("MMM");
var monthAndYearFormat = DateFormat("MMM y");
var todayDate = DateTime.now();

class LeadingActions extends StatelessWidget {
  DateTime fromDate;
  DateTime toDate;
  void Function(dynamic newFromDate, dynamic newToDate) updateTimeFrame;

  LeadingActions(
    this.fromDate,
    this.toDate,
    this.updateTimeFrame, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
        child: InkWell(
          onTap: () async {
            final selected = await showMonthYearPicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(todayDate.year - 3),
              lastDate: DateTime(todayDate.year + 3),
            );

            if (selected != null) {
              updateTimeFrame(getMonthStart(selected), getMonthEnd(selected));
            }
          },
          child: Row(children: [
            // Have to update this logic when we support timedate to be more custom than a month
            SelectedTimeFrame(fromDate: fromDate, toDate: toDate),
            const Icon(Icons.arrow_drop_down)
          ]),
        ));
  }
}

class SelectedTimeFrame extends StatelessWidget {
  const SelectedTimeFrame({
    super.key,
    required this.fromDate,
    required this.toDate,
  });

  final DateTime fromDate;
  final DateTime toDate;

  @override
  Widget build(BuildContext context) {
    return Text(
        (todayDate.year == fromDate.year && todayDate.year == toDate.year)
            ? monthFormat.format(fromDate)
            : monthAndYearFormat.format(fromDate));
  }
}
