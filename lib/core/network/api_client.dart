import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:retilda/core/config/app_config.dart';
import 'package:retilda/core/security/app_session.dart';

enum AuthScope { none, user, staff, privileged }

class ApiClient {
  ApiClient({
    required AppSession session,
    http.Client? httpClient,
  })  : _session = session,
        _httpClient = httpClient ?? http.Client();

  final AppSession _session;
  final http.Client _httpClient;

  Future<http.Response> get(
    String path, {
    AuthScope auth = AuthScope.user,
    Map<String, dynamic>? queryParameters,
    bool includeApiPrefix = true,
  }) {
    return _send(
      'GET',
      path,
      auth: auth,
      queryParameters: queryParameters,
      includeApiPrefix: includeApiPrefix,
    );
  }

  Future<http.Response> post(
    String path, {
    AuthScope auth = AuthScope.user,
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool includeApiPrefix = true,
  }) {
    return _send(
      'POST',
      path,
      auth: auth,
      body: body,
      queryParameters: queryParameters,
      includeApiPrefix: includeApiPrefix,
    );
  }

  Future<http.Response> put(
    String path, {
    AuthScope auth = AuthScope.user,
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool includeApiPrefix = true,
  }) {
    return _send(
      'PUT',
      path,
      auth: auth,
      body: body,
      queryParameters: queryParameters,
      includeApiPrefix: includeApiPrefix,
    );
  }

  Future<http.Response> delete(
    String path, {
    AuthScope auth = AuthScope.user,
    Map<String, dynamic>? queryParameters,
    bool includeApiPrefix = true,
  }) {
    return _send(
      'DELETE',
      path,
      auth: auth,
      queryParameters: queryParameters,
      includeApiPrefix: includeApiPrefix,
    );
  }

  Future<http.Response> multipart(
    String method,
    String path, {
    AuthScope auth = AuthScope.user,
    Map<String, String>? fields,
    Map<String, String>? filePaths,
    bool includeApiPrefix = true,
  }) async {
    final requestUri = uri(path, includeApiPrefix: includeApiPrefix);
    final request = http.MultipartRequest(method, requestUri);
    request.headers.addAll(await authHeaders(auth: auth, jsonContent: false));
    request.fields.addAll(fields ?? const {});

    for (final entry in (filePaths ?? const <String, String>{}).entries) {
      request.files.add(
        await http.MultipartFile.fromPath(entry.key, entry.value),
      );
    }

    _safeLog('$method $requestUri');
    try {
      final response = http.Response.fromStream(await request.send());
      final resolved = await response;
      _logResponse(method, requestUri, resolved);
      return resolved;
    } catch (error, stackTrace) {
      _logException(method, requestUri, error, stackTrace);
      rethrow;
    }
  }

  Uri uri(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool includeApiPrefix = true,
  }) {
    if (includeApiPrefix) {
      return AppConfig.apiUri(path, queryParameters: queryParameters);
    }
    return AppConfig.absoluteApiUri(path, queryParameters: queryParameters);
  }

  Future<Map<String, String>> authHeaders({
    AuthScope auth = AuthScope.user,
    bool jsonContent = true,
  }) async {
    final headers = <String, String>{};
    if (jsonContent) headers['Content-Type'] = 'application/json';
    final token = await _tokenForScope(auth);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<String?> tokenForScope(AuthScope auth) => _tokenForScope(auth);

  Future<http.Response> _send(
    String method,
    String path, {
    required AuthScope auth,
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool includeApiPrefix = true,
  }) async {
    final requestUri = uri(
      path,
      queryParameters: queryParameters,
      includeApiPrefix: includeApiPrefix,
    );
    final headers = await authHeaders(auth: auth);
    final payload = body == null || body is String ? body : jsonEncode(body);

    _safeLog('$method $requestUri');

    try {
      late final http.Response response;

      switch (method) {
        case 'GET':
          response = await _httpClient.get(requestUri, headers: headers);
          break;
        case 'POST':
          response = await _httpClient.post(requestUri,
              headers: headers, body: payload);
          break;
        case 'PUT':
          response = await _httpClient.put(requestUri,
              headers: headers, body: payload);
          break;
        case 'DELETE':
          response = await _httpClient.delete(requestUri, headers: headers);
          break;
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }

      _logResponse(method, requestUri, response);
      return response;
    } catch (error, stackTrace) {
      _logException(method, requestUri, error, stackTrace);
      rethrow;
    }
  }

  Future<String?> _tokenForScope(AuthScope auth) {
    switch (auth) {
      case AuthScope.none:
        return Future.value();
      case AuthScope.user:
        return _session.userToken();
      case AuthScope.staff:
        return _session.staffToken();
      case AuthScope.privileged:
        return _session.privilegedToken();
    }
  }

  void _safeLog(String message) {
    if (kDebugMode) {
      _debugPrintWrapped('[ApiClient] $message');
    }
  }

  void _logResponse(String method, Uri uri, http.Response response) {
    if (!kDebugMode) {
      return;
    }

    final statusLine = '[ApiClient] $method $uri -> ${response.statusCode}';
    final responseBody =
        response.body.trim().isEmpty ? '<empty>' : response.body;
    _debugPrintWrapped(statusLine);
    _debugPrintWrapped('[ApiClient][Body] $responseBody');
  }

  void _logException(
    String method,
    Uri uri,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!kDebugMode) {
      return;
    }

    _debugPrintWrapped('[ApiClient][Error] $method $uri -> $error');
    _debugPrintWrapped('[ApiClient][Stack] $stackTrace');
  }

  void _debugPrintWrapped(String message) {
    const int chunkSize = 800;
    if (message.length <= chunkSize) {
      debugPrint(message);
      return;
    }

    for (int index = 0; index < message.length; index += chunkSize) {
      final end = (index + chunkSize < message.length)
          ? index + chunkSize
          : message.length;
      debugPrint(message.substring(index, end));
    }
  }
}
