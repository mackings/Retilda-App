import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/features/wallet/data/repositories/debt_repository_impl.dart';
import 'package:retilda/features/wallet/domain/entities/debt_summary.dart';
import 'package:retilda/features/wallet/domain/repositories/debt_repository.dart';
import 'package:retilda/features/wallet/domain/usecases/get_debt_summary.dart';
import 'package:retilda/features/wallet/presentation/providers/wallet_providers.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(ref.watch(walletRemoteDataSourceProvider));
});

final getDebtSummaryProvider = Provider<GetDebtSummary>((ref) {
  return GetDebtSummary(ref.watch(debtRepositoryProvider));
});

final debtSummaryProvider = FutureProvider.autoDispose<DebtSummary>((ref) {
  return ref.watch(getDebtSummaryProvider).call();
});
