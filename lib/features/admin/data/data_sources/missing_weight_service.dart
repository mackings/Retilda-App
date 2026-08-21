import 'dart:convert';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/features/admin/data/models/missing_weight_summary.dart';

class MissingWeightService {
  MissingWeightService({
    AppSession? session,
    ApiClient? apiClient,
  }) {
    _session = session ?? AppSession();
    _apiClient = apiClient ?? ApiClient(session: _session);
  }

  late final AppSession _session;
  late final ApiClient _apiClient;

  Future<MissingWeightSummary> getMissingWeightProducts() async {
    final response = await _apiClient.get(
      'admin/products/missing-weight',
      auth: AuthScope.privileged,
    );

    if (response.statusCode != 200) {
      throw Exception('Unable to load missing-weight products');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw Exception('Unable to load missing-weight products');
    }

    final data = decoded['data'];
    return MissingWeightSummary.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }
}
