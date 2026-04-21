import 'dart:convert';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/order_status.dart';

class OrderStatusService {
  OrderStatusService({
    AppSession? session,
    ApiClient? apiClient,
  }) {
    _session = session ?? AppSession();
    _apiClient = apiClient ?? ApiClient(session: _session);
  }

  late final AppSession _session;
  late final ApiClient _apiClient;

  Future<String?> _getToken() => _session.userToken();

  Future<OrderStatusResponse> getOrderStatus(String purchaseId) async {
    final token = await _getToken();
    if (token == null) {
      return OrderStatusResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final response = await _apiClient.get('order/status/$purchaseId');

    if (response.statusCode == 200) {
      return OrderStatusResponse.fromJson(jsonDecode(response.body));
    }

    return OrderStatusResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<UpdateOrderStatusResponse> updateOrderStatus({
    required String purchaseId,
    required String orderStatus,
  }) async {
    final token = await _session.privilegedToken();
    if (token == null) {
      return UpdateOrderStatusResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final response = await _apiClient.put(
      'order/status',
      auth: AuthScope.privileged,
      body: {
        'purchaseId': purchaseId,
        'orderStatus': orderStatus,
      },
    );

    if (response.statusCode == 200) {
      return UpdateOrderStatusResponse.fromJson(jsonDecode(response.body));
    }

    return UpdateOrderStatusResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }
}
