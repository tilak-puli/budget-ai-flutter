import 'dart:convert';
import 'package:budget_ai/api.dart';
import 'package:budget_ai/models/expense.dart';
import 'package:budget_ai/utils/time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class CreateExpenseForm extends StatefulWidget {
  final Function(Expense) onExpenseCreated;

  const CreateExpenseForm({required this.onExpenseCreated, super.key});

  @override
  State<CreateExpenseForm> createState() => _CreateExpenseFormState();
}

class _CreateExpenseFormState extends State<CreateExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'Food'; // Default category
  String _description = '';
  DateTime _date = DateTime.now();
  int _amount = 0;
  bool _isLoading = false;

  // Predefined categories
  final List<String> _categories = [
    'Food',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Health',
    'Bills',
    'Other'
  ];

  // Create expense through API
  Future<void> _createExpenseViaApi() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        _formKey.currentState!.save();

        // Generate a temporary ID
        final tempId = const Uuid().v4();

        // Create a temp expense object
        final expense = Expense(
          tempId,
          _amount,
          _category,
          _description,
          _date,
          "Manually added", // Use a prompt that indicates manual creation
        );

        // Call the API
        final response = await ApiService().createExpense(expense);

        print("API response status: ${response.statusCode}");
        print("API response body: ${response.body}");

        if (response.statusCode == 200) {
          try {
            // Parse the response to get the server-generated expense with proper ID
            final responseJson = jsonDecode(response.body);
            print("Decoded response JSON: $responseJson");

            final serverExpense = Expense.fromJson(responseJson);
            print("Created server expense with ID: ${serverExpense.id}");

            // Call the callback with the server response
            widget.onExpenseCreated(serverExpense);

            // Show success and close the form
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Expense created successfully')),
            );
            Navigator.of(context).pop();
          } catch (e) {
            print("Error processing server response: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error processing server response: $e')),
            );
          }
        } else {
          // Handle error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Error: ${response.statusCode} - ${response.body}')),
          );
        }
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating expense: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Expense'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Description",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    if (value != null) {
                      _description = value;
                    }
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Category",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  isExpanded: true,
                  value: _category,
                  items:
                      _categories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _category = value;
                      });
                    }
                  },
                  onSaved: (value) {
                    if (value != null) {
                      _category = value;
                    }
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Amount",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    if (value != null) {
                      _amount = int.parse(value);
                    }
                  },
                ),
                const SizedBox(height: 20),
                InputDatePickerFormField(
                  fieldLabelText: "Date",
                  initialDate: _date,
                  firstDate: allowedStartDateTime,
                  lastDate: allowedToDateTime,
                  onDateSaved: (value) {
                    _date = value;
                  },
                ),
                const SizedBox(height: 30),
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          onPressed: _createExpenseViaApi,
                          child: const Text('Create Expense'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
