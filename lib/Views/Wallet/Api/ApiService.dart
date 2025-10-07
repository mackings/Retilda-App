import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WalletApiService {
  static const String baseUrl = 'https://retilda-fintech-3jy7.onrender.com/Api';
  
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
      print("Payload >> ${jsonEncode(requestBody)}");
      http.Response response = await http.post(
        Uri.parse('$baseUrl/installmentRepaymentUsingWallet'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Installment payment request successful');
        print('Response: ${response.body}');
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
          print('Failed to parse error response: $e');
        }

        print('Response: ${response.body}');
        print('Failed with status code: ${response.statusCode}');
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (error) {
      print('Error making installment payment request: $error');
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
      final response = await http.post(
        Uri.parse('$baseUrl/installmentRepaymentUsingCard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
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
          print('Invalid response data: ${response.body}');
          return {
            'success': false,
            'message': 'Invalid response from server',
          };
        }
      } else {
        print('Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return {
          'success': false,
          'message': 'Request failed with status: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('Exception occurred: $error');
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
      final response = await http.post(
        Uri.parse('$baseUrl/installmentRepaymentUsingWalletByPercentage'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Request Body: $requestBody');
      print('Response: ${response.body}');

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
      print("Exception: $error");
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
