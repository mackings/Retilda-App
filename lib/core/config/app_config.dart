import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String fallbackBaseUrl = 'https://retildaserver.vercel.app';
  static const String fallbackApiPathPrefix = '/Api';

  static String get baseUrl {
    final value = dotenv.maybeGet('API_BASE_URL')?.trim();
    if (value == null || value.isEmpty) return fallbackBaseUrl;
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static String get apiPathPrefix {
    final value = dotenv.maybeGet('API_PATH_PREFIX')?.trim();
    if (value == null || value.isEmpty) return fallbackApiPathPrefix;
    return value.startsWith('/') ? value : '/$value';
  }

  static Uri apiUri(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$apiPathPrefix$normalizedPath');
    return uri.replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  static Uri absoluteApiUri(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$normalizedPath');
    return uri.replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  static Set<String> get allowedWebHosts {
    final raw = dotenv.maybeGet('PAYMENT_ALLOWED_HOSTS') ?? '';
    final configured = raw
        .split(',')
        .map((host) => host.trim().toLowerCase())
        .where((host) => host.isNotEmpty)
        .toSet();
    return {
      Uri.parse(baseUrl).host.toLowerCase(),
      'checkout.paystack.com',
      'standard.paystack.co',
      'link.paystack.co',
      'paystack.co',
      'paystack.com',
      ...configured,
    };
  }
}
