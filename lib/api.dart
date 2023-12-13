import 'package:budget_ai/models/expense.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const host = !kReleaseMode ? "finance-ai-backend.onrender.com" : "localhost:3000"; 
const URI = !kReleaseMode ? Uri.https : Uri.http;

getHeaders() async {
  // String? bearer = await FirebaseAuth.instance.currentUser!.getIdToken();

  return {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6ImJlNzgyM2VmMDFiZDRkMmI5NjI3NDE2NThkMjA4MDdlZmVlNmRlNWMiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vZmluYnVkLTk5MjY5IiwiYXVkIjoiZmluYnVkLTk5MjY5IiwiYXV0aF90aW1lIjoxNzAyNDQwMTY0LCJ1c2VyX2lkIjoidG1USXFjR3BmS2YxZlVwUU9XRkdmR2FxSktlMiIsInN1YiI6InRtVElxY0dwZktmMWZVcFFPV0ZHZkdhcUpLZTIiLCJpYXQiOjE3MDI0NDAxNjQsImV4cCI6MTcwMjQ0Mzc2NCwicGhvbmVfbnVtYmVyIjoiKzkxNzg5MzM2MzEyMyIsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsicGhvbmUiOlsiKzkxNzg5MzM2MzEyMyJdfSwic2lnbl9pbl9wcm92aWRlciI6InBob25lIn19.XS57WZPpqAJStPwNcOlu_SJBdotrRMXb1_NL0wvHvuNkOEXm7gcZueo2f60R2aiVaZw6YpMUyTfKkJKIPv2agrZWeLwiytMgZwjCfQJ8fID4hzr8JjfGZuA2OpKUTksVP000E9M6rIZSIbM2UkpiQfkR-dk5iWA8_PAYhrBfsENDHK-jscrHjIMoDsP-wNqrlZuGENSL98q8FxaoneqoqmlCBs2HFsQ0vYDmHBGO7tjQ0LY68HeS9-23GZittsTdWHYtm08vdz2WB_IT_ltAGdmfp1RTStA44_uLL3EI98dhjAGCz5Bdq3yHZifDMAFhQ0rcyMNPqoUnNEeX4hEFvw'
  };
}

class ApiService {
  Future<http.Response> fetchExpenses(
      DateTime fromDate, DateTime toDate) async {
    var uri = URI(host, '/expenses', {
      "fromDate": fromDate.toUtc().toIso8601String(),
      "toDate": toDate.toUtc().toIso8601String()
    });

    return await http.get(uri, headers: await getHeaders());
  }

  Future<http.Response> addExpense(userMessage) async {
    return await http.post(URI(host, '/ai/expense'),
        headers: await getHeaders(),
        body: json.encode(<String, String>{"userMessage": userMessage}));
  }

  Future<http.Response> deleteExpense(id) async {
    return await http.delete(URI(host, '/expenses'),
        headers: await getHeaders(),
        body: json.encode(<String, String>{"id": id}));
  }

  updateExpense(Expense expense) async {
    return await http.patch(URI(host, '/expenses'),
       headers: await getHeaders(),
        body: json.encode(<String, Object>{"expense": expense.toJson()}));
  }
}
