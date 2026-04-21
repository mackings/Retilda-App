import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/core/network/api_providers.dart';
import 'package:retilda/core/security/session_providers.dart';
import 'package:retilda/features/wallet/data/data_sources/wallet_remote_data_source.dart';
import 'package:retilda/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:retilda/features/wallet/domain/entities/wallet_overview.dart';
import 'package:retilda/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:retilda/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:retilda/features/wallet/domain/usecases/get_wallet_overview.dart';

enum WalletTransactionFilter { all, debit, credit }

final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  return WalletRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
    session: ref.watch(appSessionProvider),
  );
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.watch(walletRemoteDataSourceProvider));
});

final getWalletOverviewProvider = Provider<GetWalletOverview>((ref) {
  return GetWalletOverview(ref.watch(walletRepositoryProvider));
});

final walletOverviewProvider =
    FutureProvider.autoDispose<WalletOverview>((ref) {
  return ref.watch(getWalletOverviewProvider).call();
});

final walletTransactionFilterProvider =
    StateProvider.autoDispose<WalletTransactionFilter>((ref) {
  return WalletTransactionFilter.all;
});

final filteredWalletTransactionsProvider =
    Provider.autoDispose<List<WalletTransaction>>((ref) {
  final overview = ref.watch(walletOverviewProvider).valueOrNull;
  final filter = ref.watch(walletTransactionFilterProvider);
  final transactions = overview?.transactions ?? const <WalletTransaction>[];

  switch (filter) {
    case WalletTransactionFilter.all:
      return transactions;
    case WalletTransactionFilter.debit:
      return transactions.where((transaction) => transaction.isDebit).toList();
    case WalletTransactionFilter.credit:
      return transactions.where((transaction) => !transaction.isDebit).toList();
  }
});
