import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/budget_model.dart';

class BudgetRepository {
  final SupabaseClient _supabase;

  BudgetRepository(this._supabase);

  Future<List<BudgetModel>> fetchBudgets() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((row) => BudgetModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> setBudget(BudgetModel budget) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User belum login');

    await _supabase
        .from('budgets')
        .upsert(
          budget.toUpsertJson(userId: userId),
          onConflict: 'user_id,category',
        );
  }

  Future<void> hapusBudget(String budgetId) async {
    await _supabase.from('budgets').delete().eq('id', budgetId);
  }
}
