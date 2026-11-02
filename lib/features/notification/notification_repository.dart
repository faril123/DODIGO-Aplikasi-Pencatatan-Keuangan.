import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/notification_settings_model.dart';

class NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepository(this._supabase);

  Future<NotificationSettingsModel> fetchSettings() async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) return const NotificationSettingsModel();

    final response = await _supabase
        .from('notification_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return const NotificationSettingsModel();
    return NotificationSettingsModel.fromJson(response);
  }

  Future<void> saveSettings(NotificationSettingsModel settings) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User belum login');

    final hasil = await _supabase
        .from('notification_settings')
        .upsert(settings.toUpsertJson(userId: userId), onConflict: 'user_id')
        .select();

    debugPrint('[NOTIF] hasil upsert: $hasil');
    if (hasil.isEmpty) {
      throw Exception('Pengaturan tidak tersimpan (cek RLS policy)');
    }
  }
}
