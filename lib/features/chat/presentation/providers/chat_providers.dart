import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/core/network/api_providers.dart';
import 'package:retilda/core/security/session_providers.dart';
import 'package:retilda/features/chat/data/data_sources/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(
    session: ref.watch(appSessionProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});
