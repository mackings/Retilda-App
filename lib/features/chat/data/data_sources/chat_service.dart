import 'dart:convert';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/chat.dart';

class ChatService {
  ChatService({
    AppSession? session,
    ApiClient? apiClient,
  }) {
    _session = session ?? AppSession();
    _apiClient = apiClient ?? ApiClient(session: _session);
  }

  late final AppSession _session;
  late final ApiClient _apiClient;

  Future<String?> _getToken() => _session.userToken();

  Future<StaffListResponse> listActiveStaff() async {
    final response = await _apiClient.get('staff/active', auth: AuthScope.none);

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

    final response = await _apiClient.get('chat/threads');

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

    final response = await _apiClient.post(
      'chat/start',
      body: {'staffId': staffId},
    );

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

    final response = await _apiClient.get('chat/messages/$threadId');

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

    final response = await _apiClient.post(
      'chat/message',
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

  Future<bool> closeThread(String threadId) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await _apiClient.put('chat/close/$threadId');

    return response.statusCode == 200;
  }
}
