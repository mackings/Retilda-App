import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/core/network/api_providers.dart';
import 'package:retilda/core/security/session_providers.dart';
import 'package:retilda/features/order_tracking/data/data_sources/order_status_service.dart';

final orderStatusServiceProvider = Provider<OrderStatusService>((ref) {
  return OrderStatusService(
    session: ref.watch(appSessionProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});
