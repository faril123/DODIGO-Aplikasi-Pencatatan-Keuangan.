import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/target_model.dart';
import 'target_provider.dart';

final targetDepositsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, targetId) {
      return ref.watch(targetRepositoryProvider).fetchDeposits(targetId);
    });

class TargetDetailSheet extends ConsumerWidget {
  final TargetModel target;
  const TargetDetailSheet({super.key, required this.target});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    final async = ref.watch(targetDepositsProvider(target.id));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: pal.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: pal.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: pal.outline, width: 0.5),
                  ),
                  child: Icon(Icons.history_rounded, color: pal.primaryDark),
                ).animate().scale(
                  begin: const Offset(.6, .6),
                  duration: 380.ms,
                  curve: Curves.easeOutBack,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat Setoran',
                        style: AppTextStyles.title.copyWith(fontSize: 20),
                      ),
                      Text(target.title, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: async.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Gagal memuat: $e'),
                data: (list) {
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Belum ada setoran tercatat.',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: pal.border),
                    itemBuilder: (_, i) {
                      final d = list[i];
                      final tanggal = DateTime.parse(
                        d['created_at'] as String,
                      ).toLocal();
                      final wallet =
                          (d['wallets'] as Map?)?['name'] as String? ??
                          'Wallet dihapus';
                      final nominal = (d['amount'] as num).toDouble();
                      final tarik = nominal < 0;
                      final warna = tarik ? AppColors.error : AppColors.success;

                      final item = Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: warna.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                tarik
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                size: 18,
                                color: warna,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${tarik ? '-' : '+'}${formatRupiah(nominal.abs())}',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: warna,
                                    ),
                                  ),
                                  Text(
                                    '${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(tanggal)} • $wallet',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );

                      // Hanya 8 item pertama yang beranimasi supaya scroll tetap halus.
                      return i < 8
                          ? item
                                .animate(delay: (i * 40).ms)
                                .fadeIn(duration: 300.ms)
                                .slideX(
                                  begin: .06,
                                  end: 0,
                                  duration: 350.ms,
                                  curve: Curves.easeOutCubic,
                                )
                          : item;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
