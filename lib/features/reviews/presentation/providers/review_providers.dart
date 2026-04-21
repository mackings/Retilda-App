import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/core/network/api_providers.dart';
import 'package:retilda/core/security/session_providers.dart';
import 'package:retilda/features/reviews/data/data_sources/review_service.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(
    session: ref.watch(appSessionProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});
