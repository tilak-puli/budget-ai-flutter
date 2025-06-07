import 'package:finly/theme/index.dart';
import 'package:finly/utils/time.dart';
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

    // Use a very simple button with no size constraints
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: TextButton.icon(
        icon: Text(
          displayText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        label: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
        onPressed: () async {
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
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = NeumorphicColors.lightPurpleBackground;
    final selectMonthColor = accentColor;
    // Text colors based on theme brightness
    final textColor = isDark ? Colors.white : Colors.black87;
    final selectedTextColor = Colors.white;

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
      'Dec',
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
                items:
                    List.generate(6, (index) => selectedYear - 2 + index)
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text('$year', style: TextStyle(color: textColor)),
                          ),
                        )
                        .toList(),
                onChanged: (year) {
                  if (year != null) {
                    setState(() {
                      selectedYear = year;
                    });
                  }
                },
                icon: Icon(Icons.arrow_drop_down, color: textColor),
                underline: Container(),
                dropdownColor: isDark ? Color(0xFF303030) : Colors.white,
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, size: 16, color: textColor),
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
                    icon: Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
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
                        color: isSelected ? selectedTextColor : textColor,
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
                child: Text('CANCEL', style: TextStyle(color: Colors.grey)),
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
