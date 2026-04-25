import 'dart:convert';

import 'package:retilda/Views/Admin/model/model.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';

class ApiService {
  static final AppSession _session = AppSession();
  static final ApiClient _apiClient = ApiClient(session: _session);

  static Future<String?> _getToken() => _session.privilegedToken();

  static Future<GlanceUsersPage> fetchUsers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await _apiClient.get(
      'users',
      auth: AuthScope.privileged,
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(responseData['message'] ?? 'Failed to load users');
    }

    final data = responseData['data'] as Map<String, dynamic>? ?? {};
    final usersJson = data['users'] as List? ?? const [];
    return GlanceUsersPage(
      users: usersJson
          .map((item) => GlanceUser.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: AdminPagination.fromJson(
        data['pagination'] as Map<String, dynamic>?,
        totalItemsKey: 'totalUsers',
      ),
      search: (data['filters'] as Map<String, dynamic>? ?? const {})['search']
              ?.toString() ??
          '',
    );
  }

  static Future<GlanceUserPurchasesPage> fetchUserPurchases({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await _apiClient.get(
      'getUserPurchases',
      auth: AuthScope.privileged,
      queryParameters: {
        'userId': userId,
        'page': '$page',
        'limit': '$limit',
      },
    );

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(responseData['message'] ?? 'Failed to load purchases');
    }

    final data = responseData['data'] as Map<String, dynamic>? ?? {};
    final productsJson = data['products'] as List? ?? const [];
    final purchasesJson = data['purchases'] as List? ?? const [];
    final products = productsJson
        .map((item) => GlanceProduct.fromJson(item as Map<String, dynamic>))
        .toList();

    return GlanceUserPurchasesPage(
      user: GlanceUser.fromJson(
        data['user'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      purchases: purchasesJson
          .map(
            (item) => GlancePurchase.fromJson(
              item as Map<String, dynamic>,
              products,
            ),
          )
          .toList(),
      summary: GlancePurchasesSummary.fromJson(
        data['summary'] as Map<String, dynamic>?,
      ),
      pagination: AdminPagination.fromJson(
        data['pagination'] as Map<String, dynamic>?,
        totalItemsKey: 'totalPurchases',
      ),
    );
  }
}
