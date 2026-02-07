import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retilda/model/chat.dart';

class StaffService {
  static const String _baseUrl = 'https://retildaserver.vercel.app';

  Future<String?> _getStaffToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('staffToken');
  }

  Future<String?> _getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString == null) return null;
    try {
      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      return userData['data']?['token'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getAuthToken({required String label}) async {
    final staffToken = await _getStaffToken();
    if (staffToken != null && staffToken.isNotEmpty) {
      return staffToken;
    }
    final userToken = await _getUserToken();
    if (userToken != null && userToken.isNotEmpty) {
      debugPrint('[$label] Using user token for staff/admin endpoint');
      return userToken;
    }
    return null;
  }

  Future<void> _saveStaffToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('staffToken', token);
  }

  Future<void> _saveStaffProfile(Map<String, dynamic> staff) async {
    final prefs = await SharedPreferences.getInstance();
    final role = staff['role'] as String?;
    if (role != null && role.isNotEmpty) {
      await prefs.setString('staffRole', role);
    }
    await prefs.setString('staffData', jsonEncode(staff));
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

  Future<bool> staffLogin({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/Api/staff/login');
    final headers = {'Content-Type': 'application/json'};
    final payload = jsonEncode({'email': email, 'password': password});

    _logApi(label: 'POST Staff Login', url: url, headers: headers, payload: payload);

    final response = await http.post(url, headers: headers, body: payload);

    _logApi(label: 'POST Staff Login', url: url, headers: headers, payload: payload, response: response);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['data']?['token'] as String?;
      if (token != null) {
        await _saveStaffToken(token);
        final staff = body['data']?['staff'] as Map<String, dynamic>?;
        if (staff != null) {
          await _saveStaffProfile(staff);
        }
        return true;
      }
    }
    return false;
  }

  Future<bool> setActive(bool isActive) async {
    final token = await _getAuthToken(label: 'POST Staff Active');
    if (token == null) {
      _logApi(
        label: 'POST Staff Active',
        url: Uri.parse('$_baseUrl/Api/staff/active'),
        error: 'Missing auth token',
      );
      return false;
    }

    final url = Uri.parse('$_baseUrl/Api/staff/active');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final payload = jsonEncode({'isActive': isActive});

    _logApi(label: 'POST Staff Active', url: url, headers: headers, payload: payload);

    final response = await http.post(url, headers: headers, body: payload);

    _logApi(label: 'POST Staff Active', url: url, headers: headers, payload: payload, response: response);

    return response.statusCode == 200;
  }

  Future<ThreadListResponse> listStaffThreads() async {
    final token = await _getAuthToken(label: 'GET Staff Threads');
    if (token == null) {
      return ThreadListResponse(success: false, message: 'Auth token not found');
    }

    final url = Uri.parse('$_baseUrl/Api/chat/staff/threads');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(label: 'GET Staff Threads', url: url, headers: headers);

    final response = await http.get(url, headers: headers);

    _logApi(label: 'GET Staff Threads', url: url, headers: headers, response: response);

    if (response.statusCode == 200) {
      return ThreadListResponse.fromJson(jsonDecode(response.body));
    }

    return ThreadListResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<MessageListResponse> getStaffMessages(String threadId) async {
    final token = await _getAuthToken(label: 'GET Staff Messages');
    if (token == null) {
      return MessageListResponse(success: false, message: 'Auth token not found');
    }

    final url = Uri.parse('$_baseUrl/Api/chat/staff/messages/$threadId');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(label: 'GET Staff Messages', url: url, headers: headers);

    final response = await http.get(url, headers: headers);

    _logApi(label: 'GET Staff Messages', url: url, headers: headers, response: response);

    if (response.statusCode == 200) {
      return MessageListResponse.fromJson(jsonDecode(response.body));
    }

    return MessageListResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<SendMessageResponse> sendStaffMessage({
    required String threadId,
    required String message,
  }) async {
    final token = await _getAuthToken(label: 'POST Staff Message');
    if (token == null) {
      return SendMessageResponse(success: false, message: 'Auth token not found');
    }

    final url = Uri.parse('$_baseUrl/Api/chat/staff/message');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final payload = jsonEncode({'threadId': threadId, 'message': message});

    _logApi(label: 'POST Staff Message', url: url, headers: headers, payload: payload);

    final response = await http.post(url, headers: headers, body: payload);

    _logApi(label: 'POST Staff Message', url: url, headers: headers, payload: payload, response: response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return SendMessageResponse.fromJson(jsonDecode(response.body));
    }

    return SendMessageResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<bool> closeStaffThread(String threadId) async {
    final token = await _getAuthToken(label: 'PUT Staff Close Thread');
    if (token == null) return false;

    final url = Uri.parse('$_baseUrl/Api/chat/staff/close/$threadId');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(label: 'PUT Staff Close Thread', url: url, headers: headers);

    final response = await http.put(url, headers: headers);

    _logApi(label: 'PUT Staff Close Thread', url: url, headers: headers, response: response);

    return response.statusCode == 200;
  }
}
