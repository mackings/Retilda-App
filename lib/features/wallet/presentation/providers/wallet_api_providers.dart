import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/core/network/api_providers.dart';
import 'package:retilda/core/security/session_providers.dart';
import 'package:retilda/features/wallet/data/data_sources/wallet_api_service.dart';

final walletApiServiceProvider = Provider<WalletApiService>((ref) {
  return WalletApiService(
    session: ref.watch(appSessionProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});
