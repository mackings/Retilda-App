import 'dart:convert';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/geo.dart';

class GeoService {
  GeoService({
    AppSession? session,
    ApiClient? apiClient,
  }) {
    _session = session ?? AppSession();
    _apiClient = apiClient ?? ApiClient(session: _session);
  }

  late final AppSession _session;
  late final ApiClient _apiClient;

  Future<String?> _getToken() => _session.privilegedToken();

  Future<GeoValidationResponse> validateLocation(String address) async {
    final response = await _apiClient.post(
      'geo/validate',
      auth: AuthScope.none,
      body: {'address': address},
    );

    if (response.statusCode == 200) {
      return GeoValidationResponse.fromJson(jsonDecode(response.body));
    }

    return GeoValidationResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<StateListResponse> listStates() async {
    final response = await _apiClient.get('geo/states', auth: AuthScope.none);

    if (response.statusCode == 200) {
      return StateListResponse.fromJson(jsonDecode(response.body));
    }

    return StateListResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<StateActionResponse> addState(String name) async {
    final token = await _getToken();
    if (token == null) {
      return StateActionResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final response = await _apiClient.post(
      'geo/states',
      auth: AuthScope.privileged,
      body: {'name': name},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return StateActionResponse.fromJson(jsonDecode(response.body));
    }

    return StateActionResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<StateActionResponse> deactivateState(String stateId) async {
    final token = await _getToken();
    if (token == null) {
      return StateActionResponse(
        success: false,
        message: 'Authentication token not found',
      );
    }

    final response = await _apiClient.delete(
      'geo/states/$stateId',
      auth: AuthScope.privileged,
    );

    if (response.statusCode == 200) {
      return StateActionResponse.fromJson(jsonDecode(response.body));
    }

    return StateActionResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }
}
