// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:retilda/Views/Admin/model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';



class ApiService {
  static const String baseUrl = 'https://retilda-fintech-3jy7.onrender.com/Api';

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
    if (token == null) throw Exception('Token not found');

    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

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
  if (token == null) throw Exception('Token not found');

  final response = await http.get(
    Uri.parse('$baseUrl/getUserPurchases?userId=$userId'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

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

