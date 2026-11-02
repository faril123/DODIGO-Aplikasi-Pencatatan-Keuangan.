import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/budget_model.dart';
import '../../transaction/transaction_provider.dart';
import 'budget_repository.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(Supabase.instance.client);
});

final budgetsProvider = FutureProvider.autoDispose<List<BudgetModel>>((
  ref,
) async {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.fetchBudgets();
});

/// Total pengeluaran bulan ini per kategori, diambil dari transactionsProvider yang sudah ada.
final pengeluaranPerKategoriProvider =
    Provider.autoDispose<Map<String, double>>((ref) {
      final transaksi = ref.watch(transactionsProvider).valueOrNull ?? [];
      final now = DateTime.now();

      final Map<String, double> hasil = {};
      for (final t in transaksi) {
        final bulanIni =
            t.transactionDate.year == now.year &&
            t.transactionDate.month == now.month;
        if (bulanIni && t.amount < 0) {
          hasil[t.category] = (hasil[t.category] ?? 0) + t.amount.abs();
        }
      }
      return hasil;
    });
