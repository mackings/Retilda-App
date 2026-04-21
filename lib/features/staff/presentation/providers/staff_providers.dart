import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/core/network/api_providers.dart';
import 'package:retilda/core/security/session_providers.dart';
import 'package:retilda/features/staff/data/data_sources/staff_service.dart';

final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService(
    session: ref.watch(appSessionProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});
