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
    String? productId, {
    String? purchaseId,
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

    final requestBody = {
      if (purchaseId != null && purchaseId.isNotEmpty)
        "purchaseId": purchaseId
      else
        "productId": productId,
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

  Future<Map<String, dynamic>> makeInstallmentPaymentUsingCard(
    String? productId, {
    String? purchaseId,
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
        String errorMessage = 'Request failed with status: ${response.statusCode}';
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

  Future<Map<String, dynamic>> payDebtUsingWallet(String purchaseId) async {
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
        'debt/payUsingWallet',
        body: {'purchaseId': purchaseId},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Debt paid successfully!',
          'data': responseData['data'],
        };
      } else {
        String errorMessage = 'Payment failed';
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

  Future<Map<String, dynamic>> payDebtUsingCard(String purchaseId) async {
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
        'debt/payUsingCard',
        body: {'purchaseId': purchaseId},
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
        String errorMessage = 'Request failed with status: ${response.statusCode}';
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

      final decoded = jsonDecode(response.body);
      final responseData =
          decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
      final data = responseData['data'] is Map
          ? Map<String, dynamic>.from(responseData['data'])
          : responseData;
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Delivery eligibility checked.',
          'statusCode': response.statusCode,
          'data': data,
          'raw': responseData,
        };
      }

      return {
        'success': false,
        'message':
            responseData['message'] ?? 'Unable to check delivery eligibility.',
        'statusCode': response.statusCode,
        'data': data,
        'raw': responseData,
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }
}
