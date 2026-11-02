import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/transaction_model.dart';
import 'dart:typed_data';

class TransactionRepository {
  final SupabaseClient _supabase;

  TransactionRepository(this._supabase);

  Future<List<TransactionModel>> fetchTransactions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => TransactionModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User belum login');

    await _supabase
        .from('transactions')
        .insert(transaction.toInsertJson(userId: userId));
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _supabase
        .from('transactions')
        .update(transaction.toUpdateJson())
        .eq('id', transaction.id);
  }

  Future<void> deleteTransaction(String id) async {
    await _supabase.from('transactions').delete().eq('id', id);
  }

  Future<String> uploadFoto(Uint8List bytes, String namaFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User belum login');

    final path = '$userId/$namaFile';
    await _supabase.storage
        .from('transaction-photo')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return _supabase.storage.from('transaction-photo').getPublicUrl(path);
  }
}
