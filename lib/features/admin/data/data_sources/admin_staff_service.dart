import 'dart:convert';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';

class AdminStaffService {
  AdminStaffService({
    AppSession? session,
    ApiClient? apiClient,
  }) {
    _session = session ?? AppSession();
    _apiClient = apiClient ?? ApiClient(session: _session);
  }

  late final AppSession _session;
  late final ApiClient _apiClient;

  Future<String?> _getAdminToken() => _session.privilegedToken();

  Future<String?> createStaff({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final token = await _getAdminToken();
    if (token == null) return 'Authentication token not found';

    final response = await _apiClient.post(
      'staff',
      auth: AuthScope.privileged,
      body: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return null;
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['message'] ??
          'Request failed with status: ${response.statusCode}';
    } catch (_) {
      return 'Request failed with status: ${response.statusCode}';
    }
  }
}
