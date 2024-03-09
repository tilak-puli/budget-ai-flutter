import 'package:budget_ai/models/expense.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const host = kReleaseMode ? "finance-ai-backend.onrender.com" : "127.0.0.1:5001"; 
const URI = kReleaseMode ? Uri.https : Uri.http;
const URL_PREFIX = "finbud-99269/us-central1/backend";

getHeaders() async {
  String? bearer = await FirebaseAuth.instance.currentUser!.getIdToken();

  return {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $bearer'
  };
}

class ApiService {
  Future<http.Response> fetchExpenses(
      DateTime fromDate, DateTime toDate) async {
    var uri = URI(host, '$URL_PREFIX/expenses', {
      "fromDate": fromDate.toUtc().toIso8601String(),
      "toDate": toDate.toUtc().toIso8601String()
    });

    return await http.get(uri, headers: await getHeaders());
  }

  Future<http.Response> addExpense(userMessage, date) async {
    return await http.post(URI(host, '$URL_PREFIX/ai/expense'),
        headers: await getHeaders(),
        body: json.encode(<String, String>{"userMessage": userMessage, "date": date != null ? date.toString() : ""}));
  }

  Future<http.Response> deleteExpense(id) async {
    return await http.delete(URI(host, '$URL_PREFIX/expenses'),
        headers: await getHeaders(),
        body: json.encode(<String, String>{"id": id}));
  }

  updateExpense(Expense expense) async {
    return await http.patch(URI(host, '$URL_PREFIX/expenses'),
       headers: await getHeaders(),
        body: json.encode(<String, Object>{"expense": expense.toJson()}));
  }
}
