import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:retilda/core/config/app_config.dart';
import 'package:retilda/core/presentation/session_expiry_handler.dart';
import 'package:retilda/core/security/app_session.dart';

enum AuthScope { none, user, staff, privileged }

class ApiClient {
  static const bool _verboseSuccessBodyLogging = false;

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

    _safeLogRequest(method, requestUri);
    try {
      final response = http.Response.fromStream(await request.send());
      final resolved = await response;
      _logResponse(method, requestUri, resolved);
      _handleExpiredToken(auth, resolved);
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

    _safeLogRequest(method, requestUri);

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
      _handleExpiredToken(auth, response);
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

  void _handleExpiredToken(
    AuthScope auth,
    http.Response response,
  ) {
    if (auth == AuthScope.none) return;
    if (!SessionExpiryHandler.isExpiredTokenResponse(
      statusCode: response.statusCode,
      body: response.body,
    )) {
      return;
    }

    unawaited(
      SessionExpiryHandler.handleExpiredSession(
        clearSession: () => _clearSessionForAuth(auth),
      ),
    );
  }

  Future<void> _clearSessionForAuth(AuthScope auth) async {
    switch (auth) {
      case AuthScope.none:
        return;
      case AuthScope.user:
        return _session.clearUserSession();
      case AuthScope.staff:
        return _session.clearStaffSession();
      case AuthScope.privileged:
        await _session.clearStaffSession();
        await _session.clearUserSession();
        return;
    }
  }

  void _safeLogRequest(String method, Uri uri) {
    if (!kDebugMode || _shouldSuppressSuccessfulListLog(method, uri)) {
      return;
    }

    _debugPrintWrapped('[ApiClient] $method $uri');
  }

  void _logResponse(String method, Uri uri, http.Response response) {
    if (!kDebugMode) {
      return;
    }

    if (response.statusCode < 400 &&
        _shouldSuppressSuccessfulListLog(method, uri)) {
      return;
    }

    final statusLine = '[ApiClient] $method $uri -> ${response.statusCode}';
    _debugPrintWrapped(statusLine);

    final body = response.body.trim();
    if (body.isEmpty) {
      return;
    }

    final shouldLogBody =
        response.statusCode >= 400 || _verboseSuccessBodyLogging;
    if (!shouldLogBody) {
      return;
    }

    _debugPrintWrapped('[ApiClient][Body] ${_truncateForLog(body)}');
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

  bool _shouldSuppressSuccessfulListLog(String method, Uri uri) {
    if (method != 'GET') {
      return false;
    }

    final normalizedPath = uri.path.toLowerCase();
    return normalizedPath.endsWith('/products') ||
        normalizedPath.endsWith('/products/allcategory') ||
        normalizedPath.contains('/products/category/') ||
        normalizedPath.endsWith('/products/search');
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

  String _truncateForLog(String value, {int maxLength = 1200}) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...[truncated ${value.length - maxLength} chars]';
  }
}
