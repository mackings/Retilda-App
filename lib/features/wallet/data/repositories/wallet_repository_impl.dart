import 'package:retilda/features/wallet/data/data_sources/wallet_remote_data_source.dart';
import 'package:retilda/features/wallet/domain/entities/wallet_overview.dart';
import 'package:retilda/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:retilda/features/wallet/domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._remoteDataSource);

  final WalletRemoteDataSource _remoteDataSource;

  @override
  Future<WalletOverview> getOverview() async {
    final sessionWallet = await _remoteDataSource.getSessionWallet();
    final results = await Future.wait<dynamic>([
      _remoteDataSource.getBalance(),
      _remoteDataSource.getTransactions(),
    ]);

    return WalletOverview(
      balance: results[0] as double? ??
          (sessionWallet['balance'] is num
              ? (sessionWallet['balance'] as num).toDouble()
              : null),
      accountNumber: sessionWallet['accountNumber'] as String?,
      accountName: sessionWallet['accountName'] as String?,
      bankName: 'Wema Bank',
      transactions: results[1] as List<WalletTransaction>,
    );
  }
}
