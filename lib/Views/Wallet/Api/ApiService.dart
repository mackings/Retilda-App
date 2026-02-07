import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class WalletApiService {
  static const String baseUrl = 'https://retildaserver.vercel.app/Api';

  Map<String, String> _redactHeaders(Map<String, String> headers) {
    final redacted = Map<String, String>.from(headers);
    if (redacted.containsKey('Authorization')) {
      redacted['Authorization'] = 'Bearer ***';
    }
    return redacted;
  }

  void _logApi({
    required String label,
    required Uri url,
    required Map<String, String> headers,
    Object? payload,
    http.Response? response,
    Object? error,
  }) {
    final safeHeaders = _redactHeaders(headers);
    final buffer = StringBuffer()
      ..writeln('[$label]')
      ..writeln('URL: $url')
      ..writeln('Headers: $safeHeaders')
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
  
  Future<String?> _getToken() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      return userData['data']['token'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      return {
        'token': userData['data']['token'],
        'userId': userData['data']['user']['_id'],
        'wallet': userData['data']['user']['wallet']['accountNumber'],
      };
    }
    return null;
  }

  Future<Map<String, dynamic>> makeInstallmentPaymentUsingWallet(
    String productId,
  ) async {
    String? token = await _getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Authentication token not found',
      };
    }

    Map<String, String> requestBody = {
      "productId": productId,
    };

    try {
      final url = Uri.parse('$baseUrl/installmentRepaymentUsingWallet');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final payload = jsonEncode(requestBody);

      _logApi(
        label: 'POST installmentRepaymentUsingWallet',
        url: url,
        headers: headers,
        payload: payload,
      );

      http.Response response = await http.post(
        url,
        headers: headers,
        body: payload,
      );

      _logApi(
        label: 'POST installmentRepaymentUsingWallet',
        url: url,
        headers: headers,
        payload: payload,
        response: response,
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
        } catch (e) {
          debugPrint('Failed to parse error response: $e');
        }

        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (error) {
      final url = Uri.parse('$baseUrl/installmentRepaymentUsingWallet');
      _logApi(
        label: 'POST installmentRepaymentUsingWallet',
        url: url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        payload: jsonEncode(requestBody),
        error: error,
      );
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> makeInstallmentPaymentUsingCard(
    String productId,
  ) async {
    String? token = await _getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Authentication token not found',
      };
    }

    final Map<String, String> requestBody = {
      'productId': productId,
    };

    try {
      final url = Uri.parse('$baseUrl/installmentRepaymentUsingCard');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final payload = jsonEncode(requestBody);

      _logApi(
        label: 'POST installmentRepaymentUsingCard',
        url: url,
        headers: headers,
        payload: payload,
      );

      final response = await http.post(
        url,
        headers: headers,
        body: payload,
      );

      _logApi(
        label: 'POST installmentRepaymentUsingCard',
        url: url,
        headers: headers,
        payload: payload,
        response: response,
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
    } catch (error) {
      final url = Uri.parse('$baseUrl/installmentRepaymentUsingCard');
      _logApi(
        label: 'POST installmentRepaymentUsingCard',
        url: url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        payload: jsonEncode(requestBody),
        error: error,
      );
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> topUpWalletForDelivery(
    String productId,
    dynamic targetAmount,
  ) async {
    String? token = await _getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Authentication token not found',
      };
    }

    final Map<String, dynamic> requestBody = {
      'productId': productId,
      'targetAmount': targetAmount,
    };

    try {
      final url =
          Uri.parse('$baseUrl/installmentRepaymentUsingWalletByPercentage');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final payload = jsonEncode(requestBody);

      _logApi(
        label: 'POST installmentRepaymentUsingWalletByPercentage',
        url: url,
        headers: headers,
        payload: payload,
      );

      final response = await http.post(
        url,
        headers: headers,
        body: payload,
      );

      _logApi(
        label: 'POST installmentRepaymentUsingWalletByPercentage',
        url: url,
        headers: headers,
        payload: payload,
        response: response,
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
    } catch (error) {
      final url =
          Uri.parse('$baseUrl/installmentRepaymentUsingWalletByPercentage');
      _logApi(
        label: 'POST installmentRepaymentUsingWalletByPercentage',
        url: url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        payload: jsonEncode(requestBody),
        error: error,
      );
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }

  Map<String, dynamic> calculateTopUpAmount({
    required double totalAmount,
    required double amountPaid,
  }) {
    if (totalAmount <= 0) {
      return {
        'isValid': false,
        'message': 'Total amount is invalid.',
      };
    }

    final sixtyPercent = totalAmount * 0.6;
    final amountToTopUp = sixtyPercent - amountPaid;

    if (amountToTopUp <= 0) {
      return {
        'isValid': false,
        'message': "You've already paid enough for delivery.",
        'alreadyPaid': true,
      };
    }

    final topUpPercentage = ((amountToTopUp / totalAmount) * 100).round();

    return {
      'isValid': true,
      'amountToTopUp': amountToTopUp.toInt(),
      'topUpPercentage': topUpPercentage,
      'sixtyPercent': sixtyPercent,
      'alreadyPaid': false,
    };
  }
}
