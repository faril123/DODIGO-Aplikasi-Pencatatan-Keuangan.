import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/transaction_model.dart';
import '../wallet/wallet_provider.dart';
import 'transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(Supabase.instance.client);
});

final transactionsProvider = FutureProvider.autoDispose<List<TransactionModel>>(
  (ref) async {
    final repository = ref.watch(transactionRepositoryProvider);
    return repository.fetchTransactions();
  },
);

// Ringkasan turunan dari transactionsProvider, dihitung ulang tiap ada perubahan data.
final saldoProvider = Provider.autoDispose<double>((ref) {
  final walletBalances = ref.watch(walletBalancesProvider);
  return walletBalances.fold(0.0, (sum, wb) => sum + wb.balance);
});

final ringkasanBulanIniProvider =
    Provider.autoDispose<({double pemasukan, double pengeluaran})>((ref) {
      final transaksi = ref.watch(transactionsProvider).valueOrNull ?? [];
      final now = DateTime.now();

      final bulanIni = transaksi.where(
        (t) =>
            t.transactionDate.year == now.year &&
            t.transactionDate.month == now.month,
      );

      final pemasukan = bulanIni
          .where((t) => t.amount > 0)
          .fold(0.0, (sum, t) => sum + t.amount);
      final pengeluaran = bulanIni
          .where((t) => t.amount < 0)
          .fold(0.0, (sum, t) => sum + t.amount.abs());

      return (pemasukan: pemasukan, pengeluaran: pengeluaran);
    });

final streakProvider = Provider.autoDispose<int>((ref) {
  final transaksi = ref.watch(transactionsProvider).valueOrNull ?? [];

  final hariAda = transaksi
      .map(
        (t) => DateTime(
          t.transactionDate.year,
          t.transactionDate.month,
          t.transactionDate.day,
        ),
      )
      .toSet();

  final now = DateTime.now();
  var cursor = DateTime(now.year, now.month, now.day);

  // Hari ini belum mencatat -> streak masih hidup kalau kemarin ada catatan.
  if (!hariAda.contains(cursor)) {
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }

  var streak = 0;
  while (hariAda.contains(cursor)) {
    streak++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return streak;
});
