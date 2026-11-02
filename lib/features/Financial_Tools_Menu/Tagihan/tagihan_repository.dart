import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/bill_model.dart';

class RepositoryTagihan {
  final SupabaseClient _supabase;

  RepositoryTagihan(this._supabase);

  Future<List<BillModel>> fetchBills() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('bills')
        .select()
        .eq('user_id', userId)
        .order('due_date', ascending: true);

    return (response as List)
        .map((row) => BillModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> addBill(BillModel bill) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User belum login');

    await _supabase.from('bills').insert(bill.toInsertJson(userId: userId));
  }

  /// Menandai lunas + mencatat pengeluaran di tabel transactions.
  Future<void> bayarTagihan(
    BillModel bill,
    String walletId, {
    double? nominal,
  }) async {
    await _supabase.rpc(
      'bayar_tagihan',
      params: {
        'p_bill_id': bill.id,
        'p_wallet_id': walletId,
        'p_tanggal': DateTime.now().toIso8601String().split('T').first,
        'p_nominal': nominal,
      },
    );
  }

  Future<void> updateBill(BillModel bill) async {
    await _supabase
        .from('bills')
        .update({
          'title': bill.title,
          'category': bill.category,
          'amount': bill.amount,
          'due_date': bill.dueDate.toIso8601String().split('T').first,
        })
        .eq('id', bill.id);
  }

  Future<void> deleteBill(String id) async {
    await _supabase.from('bills').delete().eq('id', id);
  }
}
