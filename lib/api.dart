import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const host = "finance-ai-backend.onrender.com";
    // : "http://localhost:3000";

class ApiService {
  Future<http.Response> fetchExpenses(DateTime fromDate, DateTime toDate) async {
    var uri = Uri.https(host, '/expenses', {"fromDate": fromDate.toUtc().toIso8601String(), "toDate": toDate.toUtc().toIso8601String()});
    
    return await http.get(uri);
  }

  Future<http.Response> addExpense(userMessage) async {
    return await http.post(Uri.https(host, '/ai/expense'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(<String, String>{"userMessage": userMessage}));
  }
}
