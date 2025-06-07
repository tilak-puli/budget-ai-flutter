import 'package:finly/models/expense.dart';
import 'package:finly/theme/index.dart';
import 'package:finly/utils/time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:finly/state/budget_store.dart';

class ExpenseForm extends StatefulWidget {
  final Expense expense;
  final Future<void> Function(Expense) updateExpense;

  const ExpenseForm(this.expense, this.updateExpense, {super.key});

  @override
  ExpenseFormState createState() => ExpenseFormState();
}

// Make the state class public so it can be referenced outside
class ExpenseFormState extends State<ExpenseForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late String category;
  late String description;
  late DateTime datetime;
  bool dateChanged = false;
  late num amount;

  // Method to expose form submission
  void submitForm(Future<void> Function(Expense) updateCallback) {
    final newExpense = Expense(
      widget.expense.id,
      amount,
      category,
      description,
      dateChanged ? datetime : widget.expense.datetime,
      widget.expense.prompt,
    );
    updateCallback(newExpense);
  }

  // Method to validate the form
  bool validate() {
    return formKey.currentState?.validate() ?? false;
  }

  // Method to save the form fields
  void save() {
    formKey.currentState?.save();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark
            ? NeumorphicColors.darkTextPrimary
            : NeumorphicColors.lightTextPrimary;
    final hintColor =
        isDark
            ? NeumorphicColors.darkTextSecondary
            : NeumorphicColors.lightTextSecondary;
    final borderColor =
        isDark ? Colors.grey.withOpacity(0.3) : Colors.grey.withOpacity(0.2);
    final fillColor =
        isDark ? Colors.grey.withOpacity(0.08) : Colors.grey.withOpacity(0.05);

    // Get categories from BudgetStore
    final budgetCategories =
        Provider.of<BudgetStore>(context, listen: false).categories;
    final allCategories = Set<String>.from(budgetCategories)
      ..add(widget.expense.category);

    // Define consistent text styles
    final labelTextStyle = TextStyle(
      fontSize: 16,
      color: hintColor,
      fontWeight: FontWeight.w500,
    );

    final inputTextStyle = TextStyle(fontSize: 16, color: textColor);

    // Clean minimal input decoration
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: fillColor,
      labelStyle: TextStyle(color: hintColor),
      hintStyle: TextStyle(fontSize: 16, color: hintColor.withOpacity(0.7)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.redAccent.withOpacity(0.8),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 14.0,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
    );

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description field
          Text('Description', style: labelTextStyle),
          const SizedBox(height: 8),
          TextFormField(
            onSaved: (value) {
              if (value != null) {
                description = value;
              }
            },
            decoration: inputDecoration.copyWith(
              hintText: "Enter description",
              prefixIcon: Icon(Icons.description_outlined, color: hintColor),
            ),
            initialValue: widget.expense.description,
            style: inputTextStyle,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Amount field
          Text('Amount', style: labelTextStyle),
          const SizedBox(height: 8),
          TextFormField(
            onSaved: (value) {
              if (value != null) {
                amount = num.parse(value);
              }
            },
            decoration: inputDecoration.copyWith(
              hintText: "Enter amount",
              prefixIcon: Icon(Icons.attach_money, color: hintColor),
            ),
            style: inputTextStyle,
            keyboardType: TextInputType.number,
            initialValue: widget.expense.amount.toString(),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Category field
          Text('Category', style: labelTextStyle),
          const SizedBox(height: 8),
          DropdownButtonFormField(
            onSaved: (value) {
              if (value != null) {
                category = value;
              }
            },
            decoration: inputDecoration.copyWith(
              prefixIcon: Icon(Icons.category_outlined, color: hintColor),
            ),
            style: inputTextStyle,
            dropdownColor:
                isDark
                    ? NeumorphicColors.darkCardBackground
                    : NeumorphicColors.lightCardBackground,
            isExpanded: true,
            value: widget.expense.category,
            items:
                allCategories.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (String? value) {},
          ),

          const SizedBox(height: 24),

          // Date field
          Text('Date', style: labelTextStyle),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8.0),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate:
                        dateChanged ? datetime : widget.expense.datetime,
                    firstDate: allowedStartDateTime,
                    lastDate: allowedToDateTime,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                            surface:
                                isDark
                                    ? NeumorphicColors.darkCardBackground
                                    : NeumorphicColors.lightCardBackground,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      datetime = picked;
                      dateChanged = true;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.calendar_today, color: hintColor),
                      ),
                      Expanded(
                        child: Text(
                          dateChanged
                              ? _getFormattedDate(datetime)
                              : _getFormattedDate(widget.expense.datetime),
                          style: inputTextStyle,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Icon(Icons.arrow_drop_down, color: hintColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format date in a readable way
  String _getFormattedDate(DateTime date) {
    final List<String> months = [
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
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
