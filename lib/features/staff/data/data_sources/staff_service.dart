import 'dart:convert';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/chat.dart';

class StaffService {
  StaffService({
    AppSession? session,
    ApiClient? apiClient,
  }) {
    _session = session ?? AppSession();
    _apiClient = apiClient ?? ApiClient(session: _session);
  }

  late final AppSession _session;
  late final ApiClient _apiClient;

  Future<String?> _getStaffToken() => _session.staffToken();

  Future<bool> staffLogin({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      'staff/login',
      auth: AuthScope.none,
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['data']?['token'] as String?;
      if (token != null) {
        final staff = body['data']?['staff'] as Map<String, dynamic>?;
        await _session.saveStaffSession(token: token, staff: staff);
        return true;
      }
    }
    return false;
  }

  Future<bool> setActive(bool isActive) async {
    final token = await _getStaffToken();
    if (token == null) {
      return false;
    }

    final response = await _apiClient.post(
      'staff/active',
      auth: AuthScope.staff,
      body: {'isActive': isActive},
    );

    return response.statusCode == 200;
  }

  Future<ThreadListResponse> listStaffThreads() async {
    final token = await _getStaffToken();
    if (token == null) {
      return ThreadListResponse(
          success: false, message: 'Auth token not found');
    }

    final response =
        await _apiClient.get('chat/staff/threads', auth: AuthScope.staff);

    if (response.statusCode == 200) {
      return ThreadListResponse.fromJson(jsonDecode(response.body));
    }

    return ThreadListResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<MessageListResponse> getStaffMessages(String threadId) async {
    final token = await _getStaffToken();
    if (token == null) {
      return MessageListResponse(
          success: false, message: 'Auth token not found');
    }

    final response = await _apiClient.get('chat/staff/messages/$threadId',
        auth: AuthScope.staff);

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
    final token = await _getStaffToken();
    if (token == null) {
      return SendMessageResponse(
          success: false, message: 'Auth token not found');
    }

    final response = await _apiClient.post(
      'chat/staff/message',
      auth: AuthScope.staff,
      body: {'threadId': threadId, 'message': message},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return SendMessageResponse.fromJson(jsonDecode(response.body));
    }

    return SendMessageResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<bool> closeStaffThread(String threadId) async {
    final token = await _getStaffToken();
    if (token == null) return false;

    final response = await _apiClient.put('chat/staff/close/$threadId',
        auth: AuthScope.staff);

    return response.statusCode == 200;
  }
}
