import 'dart:convert';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/invoice.dart';

class InvoiceService {
  InvoiceService({
    AppSession? session,
    ApiClient? apiClient,
  }) {
    _session = session ?? AppSession();
    _apiClient = apiClient ?? ApiClient(session: _session);
  }

  late final AppSession _session;
  late final ApiClient _apiClient;

  Future<String?> _getUserToken() => _session.userToken();
  Future<String?> _getPrivilegedToken() => _session.privilegedToken();

  Future<InvoiceCreateResponse> createInvoice({
    required String userId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final token = await _getPrivilegedToken();
    if (token == null) {
      return InvoiceCreateResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final response = await _apiClient.post(
      'invoices',
      auth: AuthScope.privileged,
      body: {
        'userId': userId,
        'items': items,
        if (notes != null) 'notes': notes,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return InvoiceCreateResponse.fromJson(jsonDecode(response.body));
    }

    return InvoiceCreateResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<InvoiceListResponse> listUserInvoices() async {
    final token = await _getUserToken();
    if (token == null) {
      return InvoiceListResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final response = await _apiClient.get('invoices', auth: AuthScope.user);

    if (response.statusCode == 200) {
      return InvoiceListResponse.fromJson(jsonDecode(response.body));
    }

    return InvoiceListResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<InvoiceListResponse> listAdminInvoices() async {
    final token = await _getPrivilegedToken();
    if (token == null) {
      return InvoiceListResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final response =
        await _apiClient.get('admin/invoices', auth: AuthScope.privileged);

    if (response.statusCode == 200) {
      return InvoiceListResponse.fromJson(jsonDecode(response.body));
    }

    return InvoiceListResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<InvoicePayResponse> payInvoice(String invoiceId) async {
    final token = await _getUserToken();
    if (token == null) {
      return InvoicePayResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final response =
        await _apiClient.post('invoices/$invoiceId/pay', auth: AuthScope.user);

    if (response.statusCode == 200) {
      return InvoicePayResponse.fromJson(jsonDecode(response.body));
    }

    return InvoicePayResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  String invoicePdfUrl(String invoiceId, {required String type}) {
    return _apiClient.uri('invoices/$invoiceId/pdf',
        queryParameters: {'type': type}).toString();
  }

  Future<OutstandingUserListResponse> listOutstandingUsers() async {
    final token = await _getPrivilegedToken();
    if (token == null) {
      return OutstandingUserListResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final response = await _apiClient.get('invoices/outstanding',
        auth: AuthScope.privileged);

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
    final token = await _getPrivilegedToken();
    if (token == null) {
      return OutstandingPurchaseListResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final response = await _apiClient.get(
      'invoices/outstanding/$userId',
      auth: AuthScope.privileged,
    );

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
    final token = await _getPrivilegedToken();
    if (token == null) {
      return InvoiceCreateResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final response = await _apiClient.post(
      'invoices/from-purchases',
      auth: AuthScope.privileged,
      body: {
        'userId': userId,
        'purchaseIds': purchaseIds,
        if (notes != null) 'notes': notes,
        if (dueDateIso != null) 'dueDate': dueDateIso,
      },
    );

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
    final token = await _getPrivilegedToken();
    if (token == null) {
      return InvoiceCreateResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final response = await _apiClient.post(
      'invoices/from-user',
      auth: AuthScope.privileged,
      body: {
        'userId': userId,
        if (notes != null) 'notes': notes,
        if (dueDateIso != null) 'dueDate': dueDateIso,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return InvoiceCreateResponse.fromJson(jsonDecode(response.body));
    }

    return InvoiceCreateResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }
}
