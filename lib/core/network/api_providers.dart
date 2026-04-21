import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/session_providers.dart';

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(session: ref.watch(appSessionProvider)),
);
