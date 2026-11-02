import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/target_model.dart';
import 'dart:io';

class TargetRepository {
  final SupabaseClient _supabase;

  TargetRepository(this._supabase);

  Future<List<TargetModel>> fetchTargets() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('targets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => TargetModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // ignore: strict_top_level_inference
  Future<String> uploadGambar(File file) async {
    final userId = _supabase.auth.currentUser!.id;
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _supabase.storage
        .from('target-images')
        .upload(
          path,
          file,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return _supabase.storage.from('target-images').getPublicUrl(path);
  }

  Future<void> _hapusFileLama(String? url) async {
    if (url == null || url.isEmpty || url.startsWith('emoji:')) return;
    const penanda = '/target-images/';
    final i = url.indexOf(penanda);
    if (i < 0) return;
    final path = url.substring(i + penanda.length);
    try {
      await _supabase.storage.from('target-images').remove([path]);
    } catch (_) {
      // File yatim tidak fatal.
    }
  }

  Future<void> updateTarget(
    TargetModel lama, {
    required String title,
    required double targetAmount,
    DateTime? deadline,
    String? imageUrl,
  }) async {
    await _supabase
        .from('targets')
        .update({
          'title': title,
          'target_amount': targetAmount,
          'deadline': deadline?.toIso8601String().split('T').first,
          'image_url': imageUrl,
        })
        .eq('id', lama.id);

    if (lama.imageUrl != imageUrl) await _hapusFileLama(lama.imageUrl);
  }

  Future<List<Map<String, dynamic>>> fetchDeposits(String targetId) async {
    final res = await _supabase
        .from('target_deposits')
        .select('amount, created_at, wallets(name)')
        .eq('target_id', targetId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> addTarget(TargetModel target) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User belum login');

    await _supabase.from('targets').insert(target.toInsertJson(userId: userId));
  }

  Future<void> tarikDana(
    TargetModel target,
    double nominal,
    String walletId,
  ) async {
    await _supabase.rpc(
      'tarik_dana',
      params: {
        'p_target_id': target.id,
        'p_wallet_id': walletId,
        'p_nominal': nominal,
        'p_tanggal': DateTime.now().toIso8601String().split('T').first,
      },
    );
  }

  Future<void> tambahDana(
    TargetModel target,
    double nominal,
    String walletId,
  ) async {
    await _supabase.rpc(
      'tambah_dana',
      params: {
        'p_target_id': target.id,
        'p_wallet_id': walletId,
        'p_nominal': nominal,
        'p_tanggal': DateTime.now().toIso8601String().split('T').first,
      },
    );
  }

  Future<void> tandaiDibeli(TargetModel target, String walletId) async {
    await _supabase.rpc(
      'tandai_dibeli',
      params: {
        'p_target_id': target.id,
        'p_wallet_id': walletId,
        'p_tanggal': DateTime.now().toIso8601String().split('T').first,
      },
    );
  }

  Future<void> batalkanDanKembalikan(
    TargetModel target,
    String walletId,
  ) async {
    await _supabase.rpc(
      'batalkan_dan_kembalikan',
      params: {
        'p_target_id': target.id,
        'p_wallet_id': walletId,
        'p_tanggal': DateTime.now().toIso8601String().split('T').first,
      },
    );
  }

  Future<void> hapusTarget(TargetModel target) async {
    await _supabase.from('targets').delete().eq('id', target.id);
    await _hapusFileLama(target.imageUrl);
  }
}
