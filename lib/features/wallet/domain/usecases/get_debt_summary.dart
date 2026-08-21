import 'package:retilda/features/wallet/domain/entities/debt_summary.dart';
import 'package:retilda/features/wallet/domain/repositories/debt_repository.dart';

class GetDebtSummary {
  const GetDebtSummary(this._repository);

  final DebtRepository _repository;

  Future<DebtSummary> call() {
    return _repository.getDebtSummary();
  }
}
