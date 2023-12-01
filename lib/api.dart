import 'package:budget_ai/models/expense.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const host = "localhost:3000";

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
    var uri = Uri.http(host, '/expenses', {
      "fromDate": fromDate.toUtc().toIso8601String(),
      "toDate": toDate.toUtc().toIso8601String()
    });

    return await http.get(uri, headers: await getHeaders());
  }

  Future<http.Response> addExpense(userMessage) async {
    return await http.post(Uri.http(host, '/ai/expense'),
        headers: await getHeaders(),
        body: json.encode(<String, String>{"userMessage": userMessage}));
  }

  Future<http.Response> deleteExpense(id) async {
    return await http.delete(Uri.http(host, '/expenses'),
        headers: await getHeaders(),
        body: json.encode(<String, String>{"id": id}));
  }

  updateExpense(Expense expense) async {
    return await http.patch(Uri.http(host, '/expenses'),
       headers: await getHeaders(),
        body: json.encode(<String, Object>{"expense": expense.toJson()}));
  }
}
