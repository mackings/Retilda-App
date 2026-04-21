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
    if (decoded['success'] != true) return null;
    final value = decoded['data'];
    return value is num ? value.toDouble() : null;
  }
}
