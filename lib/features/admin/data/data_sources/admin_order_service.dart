import 'dart:convert';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/purchases.dart';

class AdminOrderService {
  AdminOrderService({
    AppSession? session,
    ApiClient? apiClient,
  }) {
    _session = session ?? AppSession();
    _apiClient = apiClient ?? ApiClient(session: _session);
  }

  late final AppSession _session;
  late final ApiClient _apiClient;

  Future<String?> _getAuthToken() => _session.privilegedToken();

  Future<bool> updateOrderStatus({
    required String purchaseId,
    required String orderStatus,
  }) async {
    final token = await _getAuthToken();
    if (token == null) return false;

    final response = await _apiClient.put(
      'order/status',
      auth: AuthScope.privileged,
      body: {
        'purchaseId': purchaseId,
        'orderStatus': orderStatus,
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> updateDeliveryStatus({
    required String userId,
    required String purchaseId,
    required String deliveryStatus,
  }) async {
    final token = await _getAuthToken();
    if (token == null) return false;

    final response = await _apiClient.put(
      'products/updatedelivery',
      auth: AuthScope.privileged,
      body: {
        'userId': userId,
        'purchaseId': purchaseId,
        'deliveryStatus': deliveryStatus,
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> markDeliveryCompleted(String purchaseId) async {
    final token = await _getAuthToken();
    if (token == null) return false;

    final response = await _apiClient.put(
      'updatedPurchasesForDeliveryCompleted/$purchaseId',
      auth: AuthScope.privileged,
    );

    return response.statusCode == 200;
  }

  Future<PurchaseResponse> getReadyTrackingPurchases({
    List<String> orderStatuses = const ['processing', 'ready'],
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      return PurchaseResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final response = await _apiClient.get(
      'tracking/ready',
      auth: AuthScope.privileged,
      queryParameters: {'orderStatus': orderStatuses.join(',')},
    );

    if (response.statusCode == 200) {
      return PurchaseResponse.fromJson(jsonDecode(response.body));
    }

    return PurchaseResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }
}
