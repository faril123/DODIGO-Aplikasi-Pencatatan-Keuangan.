import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/notification_settings_model.dart';
import 'notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

final notificationSettingsProvider =
    FutureProvider.autoDispose<NotificationSettingsModel>((ref) async {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.fetchSettings();
    });
