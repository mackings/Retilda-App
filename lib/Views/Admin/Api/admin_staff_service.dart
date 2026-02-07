import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminStaffService {
  static const String _baseUrl = 'https://retildaserver.vercel.app';

  Future<String?> _getAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString == null) return null;
    final userData = jsonDecode(userDataString) as Map<String, dynamic>;
    return userData['data']?['token'];
  }

  void _logApi({
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

  Future<String?> createStaff({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final token = await _getAdminToken();
    if (token == null) return 'Authentication token not found';

    final url = Uri.parse('$_baseUrl/Api/staff');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final payload = jsonEncode({
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    });

    _logApi(label: 'POST Create Staff', url: url, headers: headers, payload: payload);

    final response = await http.post(url, headers: headers, body: payload);

    _logApi(label: 'POST Create Staff', url: url, headers: headers, payload: payload, response: response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return null;
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['message'] ?? 'Request failed with status: ${response.statusCode}';
    } catch (_) {
      return 'Request failed with status: ${response.statusCode}';
    }
  }
}
