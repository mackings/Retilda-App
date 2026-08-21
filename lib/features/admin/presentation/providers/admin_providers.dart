import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/core/network/api_providers.dart';
import 'package:retilda/core/security/session_providers.dart';
import 'package:retilda/features/admin/data/data_sources/admin_order_service.dart';
import 'package:retilda/features/admin/data/data_sources/admin_staff_service.dart';
import 'package:retilda/features/admin/data/data_sources/admin_user_service.dart'
    as admin_users;
import 'package:retilda/features/admin/data/data_sources/missing_weight_service.dart';

final adminOrderServiceProvider = Provider<AdminOrderService>((ref) {
  return AdminOrderService(
    session: ref.watch(appSessionProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});

final adminStaffServiceProvider = Provider<AdminStaffService>((ref) {
  return AdminStaffService(
    session: ref.watch(appSessionProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});

final adminUserServiceProvider = Provider<admin_users.ApiService>((ref) {
  return admin_users.ApiService();
});

final missingWeightServiceProvider = Provider<MissingWeightService>((ref) {
  return MissingWeightService(
    session: ref.watch(appSessionProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});
