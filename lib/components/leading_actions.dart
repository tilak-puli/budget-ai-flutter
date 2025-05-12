import 'package:budget_ai/theme/index.dart';
import 'package:budget_ai/utils/time.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';

var monthFormat = DateFormat("MMM");
var monthAndYearFormat = DateFormat("MMM y");
var todayDate = DateTime.now();

class LeadingActions extends StatelessWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final void Function(dynamic newFromDate, dynamic newToDate) updateTimeFrame;

  const LeadingActions(
    this.fromDate,
    this.toDate,
    this.updateTimeFrame, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Use white text on purple background
    final textColor = Colors.white;

    // Format display text based on whether it's current month/year
    String displayText;
    if (fromDate.year == todayDate.year) {
      // Same year, just show month
      displayText = monthFormat.format(fromDate);
    } else {
      // Different year, show month and year
      displayText = monthAndYearFormat.format(fromDate);
    }

    // Get theme colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? NeumorphicColors.darkAccent : NeumorphicColors.lightAccent;

    return Container(
      constraints: const BoxConstraints(
          minWidth: 100, maxWidth: 150), // Dynamic constraints for flexibility
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            // Show a custom styled month year picker with purple theme
            final selected = await showDialog<DateTime>(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  backgroundColor: isDark ? Color(0xFF303030) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: MonthYearPickerDialog(
                    fromDate: fromDate,
                    updateTimeFrame: updateTimeFrame,
                  ),
                );
              },
            );

            if (selected != null) {
              updateTimeFrame(getMonthStart(selected), getMonthEnd(selected));
            }
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    displayText,
                    style: const TextStyle(
                      color: Colors.white, // Always white on app bar
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white, // Always white on app bar
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MonthYearPickerDialog extends StatefulWidget {
  final DateTime fromDate;
  final Function(dynamic newFromDate, dynamic newToDate) updateTimeFrame;

  const MonthYearPickerDialog({
    Key? key,
    required this.fromDate,
    required this.updateTimeFrame,
  }) : super(key: key);

  @override
  State<MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<MonthYearPickerDialog> {
  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.fromDate.year;
    selectedMonth = widget.fromDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = NeumorphicColors.lightPurpleBackground;
    final selectMonthColor = accentColor;

    // Month names
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    // Current selected month display
    final selectedMonthName = months[selectedMonth - 1];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Text(
                'SELECT MONTH/YEAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$selectedMonthName $selectedYear',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Year selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<int>(
                value: selectedYear,
                items: List.generate(6, (index) => selectedYear - 2 + index)
                    .map((year) => DropdownMenuItem(
                          value: year,
                          child: Text('$year'),
                        ))
                    .toList(),
                onChanged: (year) {
                  if (year != null) {
                    setState(() {
                      selectedYear = year;
                    });
                  }
                },
                icon: const Icon(Icons.arrow_drop_down),
                underline: Container(),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, size: 16),
                    onPressed: () {
                      setState(() {
                        if (selectedMonth == 1) {
                          selectedMonth = 12;
                          selectedYear--;
                        } else {
                          selectedMonth--;
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      setState(() {
                        if (selectedMonth == 12) {
                          selectedMonth = 1;
                          selectedYear++;
                        } else {
                          selectedMonth++;
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Month grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected = month == selectedMonth;

              return InkWell(
                onTap: () {
                  setState(() {
                    selectedMonth = month;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? selectMonthColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      months[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'CANCEL',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  final selected = DateTime(selectedYear, selectedMonth);
                  Navigator.of(context).pop(selected);
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
