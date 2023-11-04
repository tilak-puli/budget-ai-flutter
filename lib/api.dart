import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const host = !kReleaseMode
    ? "https://finance-ai-backend.onrender.com"
    : "http://localhost:3000";

class ApiService {
  Future<http.Response> fetchExpenses() async {
    return await http.get(Uri.parse('$host/expenses'));
  }

  Future<http.Response> addExpense(userMessage) async {
    return await http.post(Uri.parse('$host/ai/expense'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(<String, String>{"userMessage": userMessage}));
  }
}
