import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/wallet_model.dart';
import '../../shared/models/transaction_model.dart';
import '../transaction/transaction_provider.dart';
import 'wallet_repository.dart';

class WalletBalance {
  final WalletModel wallet;
  final double balance;

  const WalletBalance({required this.wallet, required this.balance});
}

final walletBalancesProvider = Provider.autoDispose<List<WalletBalance>>((ref) {
  final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
  final transaksi =
      ref.watch(transactionsProvider).valueOrNull ?? const <TransactionModel>[];

  return wallets.map((w) {
    final totalTransaksi = transaksi
        .where((t) => t.walletId == w.id)
        .fold(0.0, (sum, t) => sum + t.amount);
    return WalletBalance(wallet: w, balance: w.initialBalance + totalTransaksi);
  }).toList();
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(Supabase.instance.client);
});

final walletsProvider = FutureProvider.autoDispose<List<WalletModel>>((
  ref,
) async {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.fetchWallets();
});
