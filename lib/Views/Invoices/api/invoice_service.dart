import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retilda/model/invoice.dart';

class InvoiceService {
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
      debugPrint('[$label] Using user token for invoice endpoint');
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

  Future<InvoiceCreateResponse> createInvoice({
    required String userId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final token = await _getAuthToken(label: 'POST Create Invoice');
    if (token == null) {
      return InvoiceCreateResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final url = Uri.parse('$_baseUrl/Api/invoices');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final payload = jsonEncode({
      'userId': userId,
      'items': items,
      if (notes != null) 'notes': notes,
    });

    _logApi(label: 'POST Create Invoice', url: url, headers: headers, payload: payload);

    final response = await http.post(url, headers: headers, body: payload);

    _logApi(label: 'POST Create Invoice', url: url, headers: headers, payload: payload, response: response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return InvoiceCreateResponse.fromJson(jsonDecode(response.body));
    }

    return InvoiceCreateResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<InvoiceListResponse> listUserInvoices() async {
    final token = await _getAuthToken(label: 'GET User Invoices');
    if (token == null) {
      return InvoiceListResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final url = Uri.parse('$_baseUrl/Api/invoices');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(label: 'GET User Invoices', url: url, headers: headers);

    final response = await http.get(url, headers: headers);

    _logApi(label: 'GET User Invoices', url: url, headers: headers, response: response);

    if (response.statusCode == 200) {
      return InvoiceListResponse.fromJson(jsonDecode(response.body));
    }

    return InvoiceListResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<InvoiceListResponse> listAdminInvoices() async {
    final token = await _getAuthToken(label: 'GET Admin Invoices');
    if (token == null) {
      return InvoiceListResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final url = Uri.parse('$_baseUrl/Api/admin/invoices');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(label: 'GET Admin Invoices', url: url, headers: headers);

    final response = await http.get(url, headers: headers);

    _logApi(label: 'GET Admin Invoices', url: url, headers: headers, response: response);

    if (response.statusCode == 200) {
      return InvoiceListResponse.fromJson(jsonDecode(response.body));
    }

    return InvoiceListResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<InvoicePayResponse> payInvoice(String invoiceId) async {
    final token = await _getAuthToken(label: 'POST Pay Invoice');
    if (token == null) {
      return InvoicePayResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final url = Uri.parse('$_baseUrl/Api/invoices/$invoiceId/pay');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(label: 'POST Pay Invoice', url: url, headers: headers);

    final response = await http.post(url, headers: headers);

    _logApi(label: 'POST Pay Invoice', url: url, headers: headers, response: response);

    if (response.statusCode == 200) {
      return InvoicePayResponse.fromJson(jsonDecode(response.body));
    }

    return InvoicePayResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  String invoicePdfUrl(String invoiceId, {required String type}) {
    return '$_baseUrl/Api/invoices/$invoiceId/pdf?type=$type';
  }

  Future<OutstandingUserListResponse> listOutstandingUsers() async {
    final token = await _getAuthToken(label: 'GET Outstanding Users');
    if (token == null) {
      return OutstandingUserListResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final url = Uri.parse('$_baseUrl/Api/invoices/outstanding');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(label: 'GET Outstanding Users', url: url, headers: headers);
    final response = await http.get(url, headers: headers);
    _logApi(label: 'GET Outstanding Users', url: url, headers: headers, response: response);

    if (response.statusCode == 200) {
      return OutstandingUserListResponse.fromJson(jsonDecode(response.body));
    }

    return OutstandingUserListResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<OutstandingPurchaseListResponse> listOutstandingPurchasesForUser(
      String userId) async {
    final token =
        await _getAuthToken(label: 'GET Outstanding Purchases For User');
    if (token == null) {
      return OutstandingPurchaseListResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final url = Uri.parse('$_baseUrl/Api/invoices/outstanding/$userId');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(
        label: 'GET Outstanding Purchases For User',
        url: url,
        headers: headers);
    final response = await http.get(url, headers: headers);
    _logApi(
        label: 'GET Outstanding Purchases For User',
        url: url,
        headers: headers,
        response: response);

    if (response.statusCode == 200) {
      return OutstandingPurchaseListResponse.fromJson(
          jsonDecode(response.body));
    }

    return OutstandingPurchaseListResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<InvoiceCreateResponse> createInvoiceFromPurchases({
    required String userId,
    required List<String> purchaseIds,
    String? notes,
    String? dueDateIso,
  }) async {
    final token =
        await _getAuthToken(label: 'POST Create Invoice From Purchases');
    if (token == null) {
      return InvoiceCreateResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final url = Uri.parse('$_baseUrl/Api/invoices/from-purchases');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final payload = jsonEncode({
      'userId': userId,
      'purchaseIds': purchaseIds,
      if (notes != null) 'notes': notes,
      if (dueDateIso != null) 'dueDate': dueDateIso,
    });

    _logApi(
        label: 'POST Create Invoice From Purchases',
        url: url,
        headers: headers,
        payload: payload);
    final response = await http.post(url, headers: headers, body: payload);
    _logApi(
        label: 'POST Create Invoice From Purchases',
        url: url,
        headers: headers,
        payload: payload,
        response: response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return InvoiceCreateResponse.fromJson(jsonDecode(response.body));
    }

    return InvoiceCreateResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<InvoiceCreateResponse> createInvoiceForUserOutstanding({
    required String userId,
    String? notes,
    String? dueDateIso,
  }) async {
    final token = await _getAuthToken(label: 'POST Create Invoice For User');
    if (token == null) {
      return InvoiceCreateResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final url = Uri.parse('$_baseUrl/Api/invoices/from-user');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final payload = jsonEncode({
      'userId': userId,
      if (notes != null) 'notes': notes,
      if (dueDateIso != null) 'dueDate': dueDateIso,
    });

    _logApi(
        label: 'POST Create Invoice For User',
        url: url,
        headers: headers,
        payload: payload);
    final response = await http.post(url, headers: headers, body: payload);
    _logApi(
        label: 'POST Create Invoice For User',
        url: url,
        headers: headers,
        payload: payload,
        response: response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return InvoiceCreateResponse.fromJson(jsonDecode(response.body));
    }

    return InvoiceCreateResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }
}
