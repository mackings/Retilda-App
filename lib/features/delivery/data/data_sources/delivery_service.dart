import 'dart:convert';
import 'package:retilda/Views/Delivery/model/deliverymodel.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';

class ApiService {
  final AppSession _session = AppSession();
  late final ApiClient _apiClient = ApiClient(session: _session);

  Future<String?> _getToken() async {
    return _session.userToken();
  }

  Future<DuePaymentResponse> getAllDuePayments() async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception("No token found. Please login again.");
    }

    final response = await _apiClient.get('getAllDuePaymentCompleted');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return DuePaymentResponse.fromJson(jsonResponse);
    } else {
      throw Exception("Failed to load due payments: ${response.statusCode}");
    }
  }
}
