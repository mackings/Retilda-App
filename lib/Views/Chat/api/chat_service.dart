import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retilda/model/chat.dart';

class ChatService {
  static const String _baseUrl = 'https://retildaserver.vercel.app';

  Future<String?> _getToken() async {
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

  Future<StaffListResponse> listActiveStaff() async {
    final url = Uri.parse('$_baseUrl/Api/staff/active');

    _logApi(label: 'GET Active Staff', url: url);

    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
    });

    _logApi(
      label: 'GET Active Staff',
      url: url,
      headers: {'Content-Type': 'application/json'},
      response: response,
    );

    if (response.statusCode == 200) {
      return StaffListResponse.fromJson(jsonDecode(response.body));
    }

    return StaffListResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<ThreadListResponse> listUserThreads() async {
    final token = await _getToken();
    if (token == null) {
      return ThreadListResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final url = Uri.parse('$_baseUrl/Api/chat/threads');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(label: 'GET User Threads', url: url, headers: headers);

    final response = await http.get(url, headers: headers);

    _logApi(
      label: 'GET User Threads',
      url: url,
      headers: headers,
      response: response,
    );

    if (response.statusCode == 200) {
      return ThreadListResponse.fromJson(jsonDecode(response.body));
    }

    return ThreadListResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<StartChatResponse> startChat(String staffId) async {
    final token = await _getToken();
    if (token == null) {
      return StartChatResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final url = Uri.parse('$_baseUrl/Api/chat/start');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final payload = jsonEncode({'staffId': staffId});

    _logApi(label: 'POST Start Chat', url: url, headers: headers, payload: payload);

    final response = await http.post(url, headers: headers, body: payload);

    _logApi(label: 'POST Start Chat', url: url, headers: headers, payload: payload, response: response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return StartChatResponse.fromJson(jsonDecode(response.body));
    }

    return StartChatResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<MessageListResponse> getMessages(String threadId) async {
    final token = await _getToken();
    if (token == null) {
      return MessageListResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final url = Uri.parse('$_baseUrl/Api/chat/messages/$threadId');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(label: 'GET Messages', url: url, headers: headers);

    final response = await http.get(url, headers: headers);

    _logApi(
      label: 'GET Messages',
      url: url,
      headers: headers,
      response: response,
    );

    if (response.statusCode == 200) {
      return MessageListResponse.fromJson(jsonDecode(response.body));
    }

    return MessageListResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<SendMessageResponse> sendMessage({
    required String threadId,
    required String message,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return SendMessageResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final url = Uri.parse('$_baseUrl/Api/chat/message');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final payload = jsonEncode({'threadId': threadId, 'message': message});

    _logApi(label: 'POST Send Message', url: url, headers: headers, payload: payload);

    final response = await http.post(url, headers: headers, body: payload);

    _logApi(label: 'POST Send Message', url: url, headers: headers, payload: payload, response: response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return SendMessageResponse.fromJson(jsonDecode(response.body));
    }

    return SendMessageResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<bool> closeThread(String threadId) async {
    final token = await _getToken();
    if (token == null) return false;

    final url = Uri.parse('$_baseUrl/Api/chat/close/$threadId');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(label: 'PUT Close Thread', url: url, headers: headers);

    final response = await http.put(url, headers: headers);

    _logApi(label: 'PUT Close Thread', url: url, headers: headers, response: response);

    return response.statusCode == 200;
  }
}
