import 'package:retilda/features/wallet/domain/entities/debt_summary.dart';

abstract class DebtRepository {
  Future<DebtSummary> getDebtSummary();
}
