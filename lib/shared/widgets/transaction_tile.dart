import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_text.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/category_style.dart';
import '../../core/utils/formatters.dart';
import '../../features/wallet/wallet_provider.dart';
import '../models/transaction_model.dart';

class TransactionTile extends ConsumerWidget {
  final TransactionModel transaction;
  final Color? borderColor;

  /// Tampilkan tanggal kecil di bawah nominal (berguna di Dashboard).
  final bool showDate;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.borderColor,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final match = wallets.where((w) => w.id == transaction.walletId);
    final walletName = match.isNotEmpty ? match.first.name : 'Wallet dihapus';

    final pal = context.pal;
    final positif = transaction.amount >= 0;
    final warna = categoryColor(transaction.category);
    final tone = positif ? pal.success : pal.error;
    final punyaFoto =
        transaction.imageUrl != null && transaction.imageUrl!.isNotEmpty;

    final border = borderColor == null
        ? pal.border
        : (borderColor == Colors.black ? pal.outline : borderColor!);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Strip warna kategori.
            Container(width: 5, color: warna),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: warna.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        categoryIcon(transaction.category),
                        color: warna,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '$walletName • ${transaction.category}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption,
                                ),
                              ),
                              if (punyaFoto) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.image_outlined,
                                  size: 14,
                                  color: pal.textSecondary,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: tone.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${positif ? '+' : ''}'
                            '${formatRupiah(transaction.amount)}',
                            style: AppTextStyles.body.copyWith(
                              color: tone,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (showDate) ...[
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'd MMM',
                              'id_ID',
                            ).format(transaction.transactionDate),
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
