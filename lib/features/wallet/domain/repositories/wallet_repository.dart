import 'package:retilda/features/wallet/domain/entities/wallet_overview.dart';

abstract class WalletRepository {
  Future<WalletOverview> getOverview();
}
