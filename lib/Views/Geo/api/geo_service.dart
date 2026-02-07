import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retilda/model/geo.dart';

class GeoService {
  static const String _baseUrl = 'https://retildaserver.vercel.app';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString == null) return null;
    final userData = jsonDecode(userDataString) as Map<String, dynamic>;
    return userData['data']?['token'];
  }

  void _logApi({
    required String label,
    required Uri url,
    Map<String, String>? headers,
    Object? payload,
    http.Response? response,
    Object? error,
  }) {
    final safeHeaders = headers == null
        ? null
        : {
            ...headers,
            if (headers.containsKey('Authorization'))
              'Authorization': 'Bearer ***',
          };

    final buffer = StringBuffer()
      ..writeln('[$label]')
      ..writeln('URL: $url')
      ..writeln('Headers: ${safeHeaders ?? "<none>"}')
      ..writeln('Payload: ${payload ?? "<none>"}');

    if (response != null) {
      buffer
        ..writeln('Status: ${response.statusCode}')
        ..writeln('Response: ${response.body}');
    }

    if (error != null) {
      buffer.writeln('Error: $error');
    }

    debugPrint(buffer.toString());
  }

  Future<GeoValidationResponse> validateLocation(String address) async {
    final url = Uri.parse('$_baseUrl/Api/geo/validate');
    final headers = {
      'Content-Type': 'application/json',
    };
    final payload = jsonEncode({'address': address});

    _logApi(label: 'POST Validate Location', url: url, headers: headers, payload: payload);

    final response = await http.post(url, headers: headers, body: payload);

    _logApi(label: 'POST Validate Location', url: url, headers: headers, payload: payload, response: response);

    if (response.statusCode == 200) {
      return GeoValidationResponse.fromJson(jsonDecode(response.body));
    }

    return GeoValidationResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }

  Future<StateListResponse> listStates() async {
    final url = Uri.parse('$_baseUrl/Api/geo/states');

    _logApi(label: 'GET Operational States', url: url);

    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
    });

    _logApi(label: 'GET Operational States', url: url, headers: {'Content-Type': 'application/json'}, response: response);

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

    final url = Uri.parse('$_baseUrl/Api/geo/states');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final payload = jsonEncode({'name': name});

    _logApi(label: 'POST Add State', url: url, headers: headers, payload: payload);

    final response = await http.post(url, headers: headers, body: payload);

    _logApi(label: 'POST Add State', url: url, headers: headers, payload: payload, response: response);

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

    final url = Uri.parse('$_baseUrl/Api/geo/states/$stateId');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    _logApi(label: 'DELETE Deactivate State', url: url, headers: headers);

    final response = await http.delete(url, headers: headers);

    _logApi(label: 'DELETE Deactivate State', url: url, headers: headers, response: response);

    if (response.statusCode == 200) {
      return StateActionResponse.fromJson(jsonDecode(response.body));
    }

    return StateActionResponse(
      success: false,
      message: 'Request failed with status: ${response.statusCode}',
    );
  }
}
