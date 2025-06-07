import 'dart:convert';
import 'package:finly/api.dart';
import 'package:finly/models/expense.dart';
import 'package:finly/theme/index.dart';
import 'package:finly/utils/time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';

class CreateExpenseForm extends StatefulWidget {
  final Function(Expense) onExpenseCreated;

  const CreateExpenseForm({required this.onExpenseCreated, super.key});

  @override
  State<CreateExpenseForm> createState() => _CreateExpenseFormState();
}

class _CreateExpenseFormState extends State<CreateExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionFocusNode = FocusNode();
  String _category = 'Food'; // Default category
  String _description = '';
  DateTime _date = DateTime.now();
  num _amount = 0;
  bool _isLoading = false;

  // Predefined categories
  final List<String> _categories = [
    'Food',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Health',
    'Bills',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionFocusNode.dispose();
    super.dispose();
  }

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

        // Fetch live location
        double? latitude;
        double? longitude;
        try {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            latitude = position.latitude;
            longitude = position.longitude;
          }
        } catch (e) {
          print('Could not fetch location: $e');
        }

        // Create a temp expense object
        final expense = Expense(
          tempId,
          _amount,
          _category,
          _description,
          _date,
          "Manually added", // Use a prompt that indicates manual creation
          latitude: latitude,
          longitude: longitude,
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
              content: Text('Error: ${response.statusCode} - ${response.body}'),
            ),
          );
        }
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating expense: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    final backgroundColor =
        isDark
            ? NeumorphicColors.darkPrimaryBackground
            : NeumorphicColors.lightPrimaryBackground;
    final accentColor =
        isDark ? NeumorphicColors.darkAccent : NeumorphicColors.lightAccent;
    final borderColor =
        isDark ? Colors.grey.withOpacity(0.3) : Colors.grey.withOpacity(0.2);
    final fillColor =
        isDark ? Colors.grey.withOpacity(0.08) : Colors.grey.withOpacity(0.05);

    // Define consistent text styles
    final labelTextStyle = TextStyle(
      fontSize: 16,
      color: hintColor,
      fontWeight: FontWeight.w500,
    );

    final inputTextStyle = TextStyle(fontSize: 16, color: textColor);

    // Section title style
    final sectionTitleStyle = TextStyle(
      fontSize: 18,
      color: textColor,
      fontWeight: FontWeight.w600,
    );

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
        borderSide: BorderSide(color: accentColor.withOpacity(0.8), width: 1.5),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Expense',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Form
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transaction Details', style: sectionTitleStyle),
                        const SizedBox(height: 24),

                        // Description field
                        Row(
                          children: [
                            Text('Description', style: labelTextStyle),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: inputDecoration.copyWith(
                            hintText: "Enter description",
                            prefixIcon: Icon(
                              Icons.description_outlined,
                              color: hintColor,
                            ),
                          ),
                          style: inputTextStyle,
                          autofocus: true,
                          focusNode: _descriptionFocusNode,
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

                        const SizedBox(height: 24),

                        // Amount field
                        Row(children: [Text('Amount', style: labelTextStyle)]),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: inputDecoration.copyWith(
                            hintText: "Enter amount",
                            prefixIcon: Icon(
                              Icons.attach_money,
                              color: hintColor,
                            ),
                          ),
                          style: inputTextStyle,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            if (value != null) {
                              _amount = num.parse(value);
                            }
                          },
                        ),

                        const SizedBox(height: 24),

                        // Category field
                        Row(
                          children: [Text('Category', style: labelTextStyle)],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField(
                          decoration: inputDecoration.copyWith(
                            prefixIcon: Icon(
                              Icons.category_outlined,
                              color: hintColor,
                            ),
                          ),
                          style: inputTextStyle,
                          dropdownColor:
                              isDark
                                  ? NeumorphicColors.darkCardBackground
                                  : NeumorphicColors.lightCardBackground,
                          isExpanded: true,
                          value: _category,
                          items:
                              _categories.map<DropdownMenuItem<String>>((
                                String value,
                              ) {
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

                        const SizedBox(height: 24),

                        // Date field
                        Row(children: [Text('Date', style: labelTextStyle)]),
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
                                  initialDate: _date,
                                  firstDate: allowedStartDateTime,
                                  lastDate: allowedToDateTime,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: Theme.of(
                                          context,
                                        ).colorScheme.copyWith(
                                          surface:
                                              isDark
                                                  ? NeumorphicColors
                                                      .darkCardBackground
                                                  : NeumorphicColors
                                                      .lightCardBackground,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null && picked != _date) {
                                  setState(() {
                                    _date = picked;
                                  });
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14.0,
                                ),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0,
                                      ),
                                      child: Icon(
                                        Icons.calendar_today,
                                        color: hintColor,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _getFormattedDate(_date),
                                        style: inputTextStyle,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 12.0,
                                      ),
                                      child: Icon(
                                        Icons.arrow_drop_down,
                                        color: hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? NeumorphicColors.darkCardBackground
                        : NeumorphicColors.lightCardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color:
                        isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.08),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cancel button
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: textColor,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Create button
                  Expanded(
                    child:
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                              onPressed: _createExpenseViaApi,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                ),
                                elevation: 2,
                                shadowColor: accentColor.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: const Text(
                                'Create',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
