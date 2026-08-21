import 'package:retilda/features/wallet/data/data_sources/wallet_remote_data_source.dart';
import 'package:retilda/features/wallet/domain/entities/debt_summary.dart';
import 'package:retilda/features/wallet/domain/repositories/debt_repository.dart';

class DebtRepositoryImpl implements DebtRepository {
  DebtRepositoryImpl(this._remoteDataSource);

  final WalletRemoteDataSource _remoteDataSource;

  @override
  Future<DebtSummary> getDebtSummary() {
    return _remoteDataSource.getDebtSummary();
  }
}
