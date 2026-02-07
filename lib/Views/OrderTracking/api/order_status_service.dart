import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retilda/model/order_status.dart';

class OrderStatusService {
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

  Future<OrderStatusResponse> getOrderStatus(String purchaseId) async {
    final token = await _getToken();
    if (token == null) {
      return OrderStatusResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final url = Uri.parse('$_baseUrl/Api/order/status/$purchaseId');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(label: 'GET Order Status', url: url, headers: headers);

    final response = await http.get(url, headers: headers);

    _logApi(
      label: 'GET Order Status',
      url: url,
      headers: headers,
      response: response,
    );

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
    final token = await _getToken();
    if (token == null) {
      return UpdateOrderStatusResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final url = Uri.parse('$_baseUrl/Api/order/status');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final payload = jsonEncode({
      'purchaseId': purchaseId,
      'orderStatus': orderStatus,
    });

    _logApi(
      label: 'PUT Update Order Status',
      url: url,
      headers: headers,
      payload: payload,
    );

    final response = await http.put(url, headers: headers, body: payload);

    _logApi(
      label: 'PUT Update Order Status',
      url: url,
      headers: headers,
      payload: payload,
      response: response,
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
