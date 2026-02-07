import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retilda/model/purchases.dart';

class AdminOrderService {
  static const String _baseUrl = 'https://retildaserver.vercel.app';

  Future<String?> _getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString == null) return null;
    final userData = jsonDecode(userDataString) as Map<String, dynamic>;
    return userData['data']?['token'];
  }

  Future<String?> _getAuthToken({required String label}) async {
    final prefs = await SharedPreferences.getInstance();
    final staffToken = prefs.getString('staffToken');
    if (staffToken != null && staffToken.isNotEmpty) {
      return staffToken;
    }
    final userToken = await _getUserToken();
    if (userToken != null && userToken.isNotEmpty) {
      debugPrint('[$label] Using user token for admin/staff endpoint');
      return userToken;
    }
    return null;
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

  Future<bool> updateOrderStatus({
    required String purchaseId,
    required String orderStatus,
  }) async {
    final token = await _getAuthToken(label: 'PUT Update Order Status');
    if (token == null) return false;

    final url = Uri.parse('$_baseUrl/Api/order/status');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final payload = jsonEncode({
      'purchaseId': purchaseId,
      'orderStatus': orderStatus,
    });

    _logApi(label: 'PUT Update Order Status', url: url, headers: headers, payload: payload);

    final response = await http.put(url, headers: headers, body: payload);

    _logApi(label: 'PUT Update Order Status', url: url, headers: headers, payload: payload, response: response);

    return response.statusCode == 200;
  }

  Future<bool> updateDeliveryStatus({
    required String userId,
    required String purchaseId,
    required String deliveryStatus,
  }) async {
    final token = await _getAuthToken(label: 'PUT Update Delivery Status');
    if (token == null) return false;

    final url = Uri.parse('$_baseUrl/Api/products/updatedelivery');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final payload = jsonEncode({
      'userId': userId,
      'purchaseId': purchaseId,
      'deliveryStatus': deliveryStatus,
    });

    _logApi(label: 'PUT Update Delivery Status', url: url, headers: headers, payload: payload);

    final response = await http.put(url, headers: headers, body: payload);

    _logApi(label: 'PUT Update Delivery Status', url: url, headers: headers, payload: payload, response: response);

    return response.statusCode == 200;
  }

  Future<bool> markDeliveryCompleted(String purchaseId) async {
    final token = await _getAuthToken(label: 'PUT Delivery Completed');
    if (token == null) return false;

    final url = Uri.parse('$_baseUrl/Api/updatedPurchasesForDeliveryCompleted/$purchaseId');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(label: 'PUT Delivery Completed', url: url, headers: headers);

    final response = await http.put(url, headers: headers);

    _logApi(label: 'PUT Delivery Completed', url: url, headers: headers, response: response);

    return response.statusCode == 200;
  }

  Future<PurchaseResponse> getReadyTrackingPurchases({
    List<String> orderStatuses = const ['processing', 'ready'],
  }) async {
    final token = await _getAuthToken(label: 'GET Tracking Ready');
    if (token == null) {
      return PurchaseResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final statusQuery = orderStatuses.join(',');
    final url = Uri.parse('$_baseUrl/Api/tracking/ready?orderStatus=$statusQuery');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(label: 'GET Tracking Ready', url: url, headers: headers);

    final response = await http.get(url, headers: headers);

    _logApi(label: 'GET Tracking Ready', url: url, headers: headers, response: response);

    if (response.statusCode == 200) {
      return PurchaseResponse.fromJson(jsonDecode(response.body));
    }

    return PurchaseResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }
}
