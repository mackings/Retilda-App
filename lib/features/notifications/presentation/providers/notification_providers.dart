import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/features/notifications/data/data_sources/notification_settings_service.dart';

final notificationSettingsServiceProvider =
    Provider<NotificationSettingsService>((ref) {
  return NotificationSettingsService();
});
