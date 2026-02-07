import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retilda/model/review.dart';

class ReviewService {
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

  Future<ReviewResponse> getProductReviews(String productId) async {
    final url = Uri.parse('$_baseUrl/Api/products/$productId/reviews');

    _logApi(label: 'GET Product Reviews', url: url);

    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
    });

    _logApi(
      label: 'GET Product Reviews',
      url: url,
      headers: {'Content-Type': 'application/json'},
      response: response,
    );

    if (response.statusCode == 200) {
      return ReviewResponse.fromJson(jsonDecode(response.body));
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ReviewResponse(
        success: false,
        message: body['message'] ?? 'Failed to load reviews',
      );
    } catch (_) {
      return ReviewResponse(
        success: false,
        message: 'Failed to load reviews',
      );
    }
  }

  Future<CreateReviewResponse> createReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return CreateReviewResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final url = Uri.parse('$_baseUrl/Api/products/$productId/reviews');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final payload = jsonEncode({
      'rating': rating,
      'comment': comment,
    });

    _logApi(
      label: 'POST Create Review',
      url: url,
      headers: headers,
      payload: payload,
    );

    final response = await http.post(url, headers: headers, body: payload);

    _logApi(
      label: 'POST Create Review',
      url: url,
      headers: headers,
      payload: payload,
      response: response,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return CreateReviewResponse.fromJson(jsonDecode(response.body));
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return CreateReviewResponse(
        success: false,
        message: body['message'] ?? 'Request failed with status: ${response.statusCode}',
      );
    } catch (_) {
      return CreateReviewResponse(
        success: false,
        message: 'Request failed with status: ${response.statusCode}',
      );
    }
  }
}
