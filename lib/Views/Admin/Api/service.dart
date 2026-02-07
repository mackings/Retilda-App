// services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:retilda/Views/Admin/model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';



class ApiService {
  static const String baseUrl = 'https://retildaserver.vercel.app/Api';

  static void _logApi({
    required String label,
    required Uri url,
    Map<String, String>? headers,
    Object? payload,
    http.Response? response,
    Object? error,
  }) {
    final safeHeaders = headers == null
        ? null
        : {
            ...headers,
            if (headers.containsKey('Authorization'))
              'Authorization': 'Bearer ***',
          };

    final buffer = StringBuffer()
      ..writeln('[$label]')
      ..writeln('URL: $url')
      ..writeln('Headers: ${safeHeaders ?? "<none>"}')
      ..writeln('Payload: ${payload ?? "<none>"}');

    if (response != null) {
      buffer
        ..writeln('Status: ${response.statusCode}')
        ..writeln('Response: ${response.body}');
    }

    if (error != null) {
      buffer.writeln('Error: $error');
    }

    debugPrint(buffer.toString());
  }

  // Get token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString != null) {
      final Map<String, dynamic> userData = jsonDecode(userDataString);
      return userData['data']['token'];
    }
    return null;
  }

  // Get all users
  static Future<List<GlanceUser>> fetchUsers() async {
    final token = await _getToken();
    if (token == null) {
      _logApi(
        label: 'GET Sales Users',
        url: Uri.parse('$baseUrl/users'),
        error: 'Token not found',
      );
      throw Exception('Token not found');
    }

    final url = Uri.parse('$baseUrl/users');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(label: 'GET Sales Users', url: url, headers: headers);

    final response = await http.get(url, headers: headers);

    _logApi(label: 'GET Sales Users', url: url, headers: headers, response: response);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List usersJson = data['data'];
      return usersJson.map((json) => GlanceUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }



// Get purchases of a specific user
// Get purchases of a specific user
static Future<List<GlancePurchase>> fetchUserPurchases(String userId) async {
  final token = await _getToken();
  if (token == null) {
    _logApi(
      label: 'GET Sales User Purchases',
      url: Uri.parse('$baseUrl/getUserPurchases?userId=$userId'),
      error: 'Token not found',
    );
    throw Exception('Token not found');
  }

  final url = Uri.parse('$baseUrl/getUserPurchases?userId=$userId');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  _logApi(label: 'GET Sales User Purchases', url: url, headers: headers);

  final response = await http.get(url, headers: headers);

  _logApi(label: 'GET Sales User Purchases', url: url, headers: headers, response: response);

  final responseData = jsonDecode(response.body);

  // Case: no purchases found (API returns 404 with success: false)
  if (response.statusCode == 404 && responseData['message'] != null) {
    throw Exception(responseData['message']); // e.g. "No purchases found..."
  }

  if (response.statusCode == 200) {
    final data = responseData['data'];

    // Map products
    List productsJson = data['products'] ?? [];
    List<GlanceProduct> products =
        productsJson.map((p) => GlanceProduct.fromJson(p)).toList();

    // Map purchases
    List purchasesJson = data['purchases'] ?? [];
    return purchasesJson.map((p) => GlancePurchase.fromJson(p, products)).toList();
  } else {
    throw Exception('Failed to load purchases');
  }
}


}
