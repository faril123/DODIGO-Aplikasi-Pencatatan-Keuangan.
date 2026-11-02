import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/wallet_model.dart';

class WalletRepository {
  final SupabaseClient _supabase;

  WalletRepository(this._supabase);

  Future<List<WalletModel>> fetchWallets() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((row) => WalletModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> addWallet(WalletModel wallet) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User belum login');

    await _supabase.from('wallets').insert(wallet.toInsertJson(userId: userId));
  }

  Future<void> updateWallet(WalletModel wallet) async {
    await _supabase
        .from('wallets')
        .update({'name': wallet.name, 'type': wallet.type.value})
        .eq('id', wallet.id);
  }

  Future<int> hitungTransaksiTerkait(String walletId) async {
    final response = await _supabase
        .from('transactions')
        .select('id')
        .eq('wallet_id', walletId);
    return (response as List).length;
  }

  Future<void> deleteWallet(String walletId) async {
    await _supabase.from('wallets').delete().eq('id', walletId);
  }
}
