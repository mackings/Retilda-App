import 'dart:convert';

import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/features/wallet/data/models/wallet_transaction_model.dart';

class WalletRemoteDataSource {
  WalletRemoteDataSource({
    required ApiClient apiClient,
    required AppSession session,
  })  : _apiClient = apiClient,
        _session = session;

  final ApiClient _apiClient;
  final AppSession _session;

  Future<Map<String, dynamic>> getSessionWallet() async {
    final userData = await _session.userData();
    final user = userData?['data']?['user'] as Map<String, dynamic>?;
    final wallet = user?['wallet'] as Map<String, dynamic>?;

    return {
      'accountNumber': wallet?['accountNumber']?.toString(),
      'accountName': wallet?['accountName']?.toString(),
      'balance': user?['balance'],
    };
  }

  Future<List<WalletTransactionModel>> getTransactions() async {
    final response = await _apiClient.get('viewTransactionHistory');
    if (response.statusCode != 200) {
      throw Exception('Unable to load transactions');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawTransactions = decoded['transactions'];
    if (rawTransactions is! List) return const [];

    return rawTransactions
        .whereType<Map<String, dynamic>>()
        .map(WalletTransactionModel.fromJson)
        .toList();
  }

  Future<double?> getBalance() async {
    final response = await _apiClient.get('userBalance');
    if (response.statusCode != 200) {
      throw Exception('Unable to load wallet balance');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['success'] == false || decoded['status'] == false) return null;

    return _extractBalance(decoded);
  }

  double? _extractBalance(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
      if (normalized.isEmpty) return null;
      return double.tryParse(normalized);
    }
    if (value is Map<String, dynamic>) {
      for (final key in const [
        'balance',
        'walletBalance',
        'availableBalance',
        'amount',
      ]) {
        final parsed = _extractBalance(value[key]);
        if (parsed != null) return parsed;
      }

      for (final key in const ['data', 'wallet', 'user']) {
        final parsed = _extractBalance(value[key]);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
