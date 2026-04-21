// services/api_service.dart
import 'dart:convert';
import 'package:retilda/Views/Admin/model/model.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';

class ApiService {
  static final AppSession _session = AppSession();
  static final ApiClient _apiClient = ApiClient(session: _session);

  static Future<String?> _getToken() => _session.privilegedToken();

  // Get all users
  static Future<List<GlanceUser>> fetchUsers() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await _apiClient.get('users', auth: AuthScope.privileged);

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
      throw Exception('Token not found');
    }

    final response = await _apiClient.get(
      'getUserPurchases',
      auth: AuthScope.privileged,
      queryParameters: {'userId': userId},
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
      return purchasesJson
          .map((p) => GlancePurchase.fromJson(p, products))
          .toList();
    } else {
      throw Exception('Failed to load purchases');
    }
  }
}
