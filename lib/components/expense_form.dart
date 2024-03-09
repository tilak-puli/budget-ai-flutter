import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/utils/time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpenseForm extends StatefulWidget {
  final Expense expense;
  final Future<void> Function(Expense) updateExpense;

  const ExpenseForm(
    this.expense,
    this.updateExpense, {
    super.key,
  });

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late String category;
  late String description;
  late DateTime datetime;
  bool dateChanged = false;
  late int amount;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            onSaved: (value) {
              if (value != null) {
                description = value;
              }
            },
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Description",
                floatingLabelBehavior: FloatingLabelBehavior.always),
            initialValue: widget.expense.description,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField(
            onSaved: (value) {
              if (value != null) {
                category = value;
              }
            },
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Category",
                floatingLabelBehavior: FloatingLabelBehavior.always),
            isExpanded: true,
            value: widget.expense.category,
            items: [widget.expense.category]
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? value) {},
          ),
          const SizedBox(height: 20),
          TextFormField(
            onSaved: (value) {
              if (value != null) {
                amount = int.parse(value);
              }
            },
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Amount",
                floatingLabelBehavior: FloatingLabelBehavior.always),
            keyboardType: TextInputType.number,
            initialValue: widget.expense.amount.toString(),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          InputDatePickerFormField(
              onDateSaved: (value) {
                dateChanged = true;
                datetime = value;
              },
              fieldLabelText: "Date",
              initialDate: widget.expense.datetime,
              firstDate: allowedStartDateTime,
              lastDate: allowedToDateTime),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  var newExpense = Expense(
                      widget.expense.id,
                      amount,
                      category,
                      description,
                      dateChanged ? datetime : widget.expense.datetime,
                      widget.expense.prompt);
                  widget.updateExpense(newExpense);
                }
              },
              child: const Text('Update'),
            ),
          ),
        ],
      ),
    );
  }
}
