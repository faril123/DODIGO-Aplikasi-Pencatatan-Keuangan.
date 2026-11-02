import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_text.dart';
import '../../core/utils/category_style.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_palette.dart';
import '../../features/transaction/transaction_provider.dart';
import '../../features/wallet/wallet_provider.dart';
import '../../features/notification/notification_prompt.dart';
import '../models/transaction_model.dart';

void showTransactionDetail(BuildContext context, TransactionModel transaction) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TransactionDetailSheet(transaction: transaction),
  );
}

class _TransactionDetailSheet extends ConsumerWidget {
  final TransactionModel transaction;

  const _TransactionDetailSheet({required this.transaction});

  Future<void> _hapus(BuildContext context, WidgetRef ref) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text('Transaksi ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (konfirmasi != true) return;

    try {
      await ref
          .read(transactionRepositoryProvider)
          .deleteTransaction(transaction.id);
      ref.invalidate(transactionsProvider);
      await jadwalkanUlangSemua(ref);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus transaksi: $e')),
        );
      }
    }
  }

  void _lihatFotoPenuh(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positif = transaction.amount >= 0;
    final warna = categoryColor(transaction.category);
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final walletMatch = wallets.where((w) => w.id == transaction.walletId);
    final walletName = walletMatch.isNotEmpty
        ? walletMatch.first.name
        : 'Wallet dihapus';
    final merah = context.pal.error;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.pal.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.pal.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/add-transaction', extra: transaction);
                    },
                  ),
                ],
              ),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: warna.withValues(alpha: 0.15),
                      child: Icon(
                        categoryIcon(transaction.category),
                        color: warna,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formatRupiah(transaction.amount),
                      style: AppTextStyles.heading.copyWith(
                        color: positif ? context.pal.success : merah,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(transaction.title, style: AppTextStyles.title),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildBaris('Kategori', transaction.category),
              _buildBaris('Sumber Dana', walletName),
              _buildBaris(
                'Tanggal',
                DateFormat(
                  'd MMMM yyyy',
                  'id_ID',
                ).format(transaction.transactionDate),
              ),
              if (transaction.title != transaction.category)
                _buildBaris('Catatan', transaction.title),
              if (transaction.imageUrl != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Foto Bukti',
                  style: AppTextStyles.title.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _lihatFotoPenuh(context, transaction.imageUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      transaction.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _hapus(context, ref),
                icon: Icon(Icons.delete_outline, color: merah),
                label: Text('Hapus Transaksi', style: TextStyle(color: merah)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: merah),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBaris(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
