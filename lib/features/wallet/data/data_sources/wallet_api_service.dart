import 'dart:convert';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';

class WalletApiService {
  WalletApiService({
    AppSession? session,
    ApiClient? apiClient,
  }) {
    _session = session ?? AppSession();
    _apiClient = apiClient ?? ApiClient(session: _session);
  }

  late final AppSession _session;
  late final ApiClient _apiClient;

  Future<String?> _getToken() async {
    return _session.userToken();
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final userData = await _session.userData();
    if (userData != null) {
      return {
        'token': await _session.userToken(),
        'userId': userData['data']['user']['_id'],
        'wallet': userData['data']['user']['wallet']['accountNumber'],
      };
    }
    return null;
  }

  Future<Map<String, dynamic>> makeInstallmentPaymentUsingWallet(
      String productId,
      {String? purchaseId}) async {
    String? token = await _getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Authentication token not found',
      };
    }

    final requestBody = {
      "productId": productId,
      if (purchaseId != null && purchaseId.isNotEmpty) "purchaseId": purchaseId,
    };

    try {
      final response = await _apiClient.post(
        'installmentRepaymentUsingWallet',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Payment successful!',
          'data': jsonDecode(response.body),
        };
      } else {
        String errorMessage = 'Payment Error, kindly retry';
        try {
          final responseData = jsonDecode(response.body);
          if (responseData is Map && responseData.containsKey('message')) {
            errorMessage = responseData['message'];
          }
        } catch (_) {}

        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (_) {
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> makeInstallmentPaymentUsingCard(String productId,
      {String? purchaseId}) async {
    String? token = await _getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Authentication token not found',
      };
    }

    final Map<String, String> requestBody = {
      'productId': productId,
      if (purchaseId != null && purchaseId.isNotEmpty) 'purchaseId': purchaseId,
    };

    try {
      final response = await _apiClient.post(
        'installmentRepaymentUsingCard',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true &&
            responseData['data'] != null &&
            responseData['data']['paymentUrl'] != null) {
          return {
            'success': true,
            'paymentUrl': responseData['data']['paymentUrl'],
            'data': responseData,
          };
        } else {
          return {
            'success': false,
            'message': 'Invalid response from server',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Request failed with status: ${response.statusCode}',
        };
      }
    } catch (_) {
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> calculateDeliveryEligibility(
    String purchaseId,
  ) async {
    String? token = await _getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Authentication token not found',
      };
    }

    if (purchaseId.isEmpty) {
      return {
        'success': false,
        'message': 'Purchase details not found.',
      };
    }

    try {
      final response = await _apiClient.post(
        'requestForGoodsDeliveryCalculation/$purchaseId',
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Delivery eligibility checked.',
          'data': responseData['data'],
          'raw': responseData,
        };
      }

      return {
        'success': false,
        'message':
            responseData['message'] ?? 'Unable to check delivery eligibility.',
        'data': responseData['data'],
        'raw': responseData,
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> topUpWalletForDelivery({
    String? purchaseId,
    String? productId,
    dynamic targetAmount,
  }) async {
    String? token = await _getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Authentication token not found',
      };
    }

    if ((purchaseId == null || purchaseId.isEmpty) &&
        (productId == null || productId.isEmpty)) {
      return {
        'success': false,
        'message': 'Purchase details not found.',
      };
    }

    final Map<String, dynamic> requestBody = {
      if (purchaseId != null && purchaseId.isNotEmpty)
        'purchaseId': purchaseId
      else
        'productId': productId,
      if (targetAmount != null) 'targetAmount': targetAmount,
    };

    try {
      final response = await _apiClient.post(
        'installmentRepaymentUsingWalletByPercentage',
        body: requestBody,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': 'Top-up successful',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'An error occurred.',
          'data': responseData,
        };
      }
    } catch (_) {
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }
}
