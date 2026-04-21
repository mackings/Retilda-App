import 'dart:convert';

import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/review.dart';

class ReviewService {
  ReviewService({
    AppSession? session,
    ApiClient? apiClient,
  }) {
    _session = session ?? AppSession();
    _apiClient = apiClient ?? ApiClient(session: _session);
  }

  late final AppSession _session;
  late final ApiClient _apiClient;

  Future<String?> _getToken() => _session.userToken();

  Future<ReviewResponse> getProductReviews(String productId) async {
    final response = await _apiClient.get(
      'products/$productId/reviews',
      auth: AuthScope.none,
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

    final response = await _apiClient.post(
      'products/$productId/reviews',
      body: {
        'rating': rating,
        'comment': comment,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return CreateReviewResponse.fromJson(jsonDecode(response.body));
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return CreateReviewResponse(
        success: false,
        message: body['message'] ??
            'Request failed with status: ${response.statusCode}',
      );
    } catch (_) {
      return CreateReviewResponse(
        success: false,
        message: 'Request failed with status: ${response.statusCode}',
      );
    }
  }
}
