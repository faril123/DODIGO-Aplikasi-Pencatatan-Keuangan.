import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/rupiah_input_formatter.dart';
import '../../../core/theme/app_palette.dart';

import '../../../shared/models/target_model.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/header_line.dart';
import '../../../shared/widgets/pressable_scale.dart';

import '../../notification/notification_prompt.dart';
import '../../transaction/transaction_provider.dart';
import '../../wallet/wallet_provider.dart';

import 'target_detail_sheet.dart';
import 'target_withdraw_sheet.dart';
import 'target_edit_sheet.dart';
import 'target_provider.dart';
import 'target_form_widgets.dart';
import 'target_confetti.dart';

final filterTargetProvider = StateProvider<int>((ref) => 0);

class TargetPage extends ConsumerWidget {
  const TargetPage({super.key});

  // ============================================================
  // AKSI
  // ============================================================

  void _bukaFormTarget(BuildContext context, WidgetRef ref) {
    showAppSheet(context, (_) => const _TargetFormSheet());
  }

  void _bukaEdit(BuildContext context, TargetModel target) {
    showAppSheet(context, (_) => TargetEditSheet(target: target));
  }

  void _bukaTarik(BuildContext context, TargetModel target) {
    showAppSheet(context, (_) => TargetWithdrawSheet(target: target));
  }

  void _bukaRiwayat(BuildContext context, TargetModel target) {
    showAppSheet(context, (_) => TargetDetailSheet(target: target));
  }

  Future<void> _hapusBerjalan(
    BuildContext context,
    WidgetRef ref,
    TargetModel target,
  ) async {
    final adaDana = target.currentAmount > 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus "${target.title}"?'),
        content: Text(
          adaDana
              ? 'Dana ${formatRupiah(target.currentAmount)} akan dikembalikan ke wallet yang kamu pilih.'
              : 'Target ini akan dihapus.',
        ),
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
    if (ok != true || !context.mounted) return;

    String? walletId;
    if (adaDana) {
      walletId = await _pilihWallet(
        context,
        ref,
        'Kembalikan dana ke wallet mana?',
      );
      if (walletId == null) return;
    }

    try {
      final repo = ref.read(targetRepositoryProvider);
      if (walletId != null) await repo.batalkanDanKembalikan(target, walletId);
      await repo.hapusTarget(target);
      ref.invalidate(targetsProvider);
      ref.invalidate(transactionsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus target: $e')));
      }
    }
  }

  void _bukaFormTambahDana(
    BuildContext context,
    WidgetRef ref,
    TargetModel target,
  ) {
    showAppSheet(context, (_) => _TambahDanaSheet(target: target));
  }

  void _bukaDialogTercapai(
    BuildContext context,
    WidgetRef ref,
    TargetModel target,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('"${target.title}" tercapai!'),
        content: const Text('Sudah dibelikan barangnya?'),
        actions: [
          TextButton(
            onPressed: () => _prosesTidakJadi(ctx, context, ref, target),
            child: const Text('Tidak Jadi'),
          ),
          FilledButton(
            onPressed: () => _prosesSudahDibeli(ctx, context, ref, target),
            child: const Text('Ya, Sudah Dibeli'),
          ),
        ],
      ),
    );
  }

  Future<String?> _pilihWallet(
    BuildContext context,
    WidgetRef ref,
    String judul,
  ) async {
    final wallets = await ref.read(walletsProvider.future);
    if (wallets.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada wallet. Buat dulu di halaman Akun.'),
          ),
        );
      }
      return null;
    }
    if (!context.mounted) return null;

    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(judul),
        children: wallets
            .map(
              (w) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, w.id),
                child: Text(w.name),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _prosesSudahDibeli(
    BuildContext dialogContext,
    BuildContext context,
    WidgetRef ref,
    TargetModel target,
  ) async {
    Navigator.pop(dialogContext);
    final walletId = await _pilihWallet(
      context,
      ref,
      'Dibeli pakai wallet mana? (untuk catatan riwayat)',
    );
    if (walletId == null) return;

    try {
      await ref.read(targetRepositoryProvider).tandaiDibeli(target, walletId);
      ref.invalidate(targetsProvider);
      ref.invalidate(transactionsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menandai selesai: $e')));
      }
    }
  }

  Future<void> _prosesTidakJadi(
    BuildContext dialogContext,
    BuildContext context,
    WidgetRef ref,
    TargetModel target,
  ) async {
    Navigator.pop(dialogContext);
    final walletId = await _pilihWallet(
      context,
      ref,
      'Kembalikan dana ke wallet mana?',
    );
    if (walletId == null) return;

    try {
      await ref
          .read(targetRepositoryProvider)
          .batalkanDanKembalikan(target, walletId);
      ref.invalidate(targetsProvider);
      ref.invalidate(transactionsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengembalikan dana: $e')));
      }
    }
  }

  Future<void> _konfirmasiHapus(
    BuildContext context,
    WidgetRef ref,
    TargetModel target,
  ) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus "${target.title}"?'),
        content: const Text(
          'Riwayat transaksi terkait target ini tetap ada, cuma kartu ini yang dihapus.',
        ),
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
      await ref.read(targetRepositoryProvider).hapusTarget(target);
      ref.invalidate(targetsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus target: $e')));
      }
    }
  }

  // ============================================================
  // HELPER
  // ============================================================

  ({String teks, Color warna})? _statusDeadline(
    BuildContext context,
    TargetModel t,
  ) {
    if (t.deadline == null || !t.masihBerjalan) return null;
    final now = DateTime.now();
    final d = t.deadline!;
    final sisa = DateTime(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (sisa < 0) {
      return (teks: 'Terlambat ${-sisa} hari', warna: AppColors.error);
    }
    if (sisa == 0) {
      return (teks: 'Jatuh tempo hari ini', warna: AppColors.error);
    }
    if (sisa <= 7) {
      return (teks: 'Sisa $sisa hari', warna: AppColors.primaryDark);
    }
    return (teks: 'Sisa $sisa hari', warna: context.pal.textSecondary);
  }

  String? _saranTabung(TargetModel t) {
    if (t.deadline == null || !t.masihBerjalan || t.sudahTercapai) return null;
    final now = DateTime.now();
    final d = t.deadline!;
    final hari = DateTime(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (hari <= 0) return null;
    final sisaDana = t.targetAmount - t.currentAmount;
    if (hari <= 31) {
      return 'Nabung ${formatRupiah((sisaDana / hari).ceilToDouble())}/hari agar tepat waktu';
    }
    final bulan = (hari / 30).ceil();
    return 'Nabung ${formatRupiah((sisaDana / bulan).ceilToDouble())}/bulan agar tepat waktu';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetsAsync = ref.watch(targetsProvider);
    final filter = ref.watch(filterTargetProvider);

    return ColoredBox(
      color: context.pal.background,
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, ref),
                _buildFilter(context, ref, filter),
                Expanded(
                  child: targetsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) =>
                        Center(child: Text('Gagal memuat data: $err')),
                    data: (targets) {
                      final aktif = targets
                          .where((t) => t.masihBerjalan)
                          .toList();
                      final selesai = targets
                          .where((t) => !t.masihBerjalan)
                          .toList();
                      final tampil = switch (filter) {
                        0 => aktif,
                        1 => selesai,
                        _ => targets,
                      };

                      if (tampil.isEmpty) {
                        return _buildKosong(context, targets.isEmpty);
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          if (filter != 1 && aktif.isNotEmpty) ...[
                            _buildBanner(context, aktif)
                                .animate(key: ValueKey('banner-$filter'))
                                .fadeIn(duration: 350.ms)
                                .slideY(
                                  begin: .1,
                                  end: 0,
                                  duration: 400.ms,
                                  curve: Curves.easeOutCubic,
                                ),
                            const SizedBox(height: 16),
                          ],
                          for (var i = 0; i < tampil.length; i++)
                            _buildTargetCard(context, ref, tampil[i])
                                .animate(
                                  key: ValueKey('t-${tampil[i].id}-$filter'),
                                  delay: (80 + i.clamp(0, 6) * 60).ms,
                                )
                                .fadeIn(duration: 350.ms)
                                .slideY(
                                  begin: .12,
                                  end: 0,
                                  duration: 420.ms,
                                  curve: Curves.easeOutCubic,
                                ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKosong(BuildContext context, bool belumAda) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.pal.primaryLight,
                    border: Border.all(color: context.pal.outline, width: 0.5),
                  ),
                  child: Icon(
                    Icons.savings_outlined,
                    size: 42,
                    color: context.pal.primaryDark,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                  begin: 0,
                  end: -8,
                  duration: 1400.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 16),
            Text(
              belumAda
                  ? 'Belum ada target.\nTekan + untuk membuat target baru.'
                  : 'Tidak ada target di kategori ini.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
          child: Row(
            children: [
              PressableScale(
                scale: .9,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go('/dashboard'),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.pal.card,
                      border: Border.all(
                        color: context.pal.outline,
                        width: 0.5,
                      ),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Target Saya',
                  style: AppTextStyles.title.copyWith(fontSize: 20),
                ),
              ),
              PressableScale(
                scale: .9,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _bukaFormTarget(context, ref);
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      border: Border.all(
                        color: context.pal.outline,
                        width: 0.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 24,
                      color: Color(0xFF2B1B10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: HeaderLine(),
        ),
      ],
    );
  }

  Widget _buildFilter(BuildContext context, WidgetRef ref, int aktif) {
    const label = ['Aktif', 'Selesai', 'Semua'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: List.generate(3, (i) {
          final selected = aktif == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PressableScale(
              scale: .94,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (selected) return;
                  HapticFeedback.selectionClick();
                  ref.read(filterTargetProvider.notifier).state = i;
                },
                child: AnimatedContainer(
                  duration: 200.ms,
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : context.pal.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primary : context.pal.outline,
                      width: 0.5,
                    ),
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: 200.ms,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFF2B1B10)
                          : context.pal.textSecondary,
                    ),
                    child: Text(label[i]),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, List<TargetModel> aktif) {
    final rata = aktif.fold<double>(0, (a, t) => a + t.progress) / aktif.length;
    final persen = (rata * 100).round();
    final judul = persen < 30
        ? 'Ayo mulai! 💪'
        : persen < 70
        ? 'Niceee!!! 🔥'
        : 'Hampir sampai! 🎉';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.pal.primaryLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.pal.outline, width: 0.5),
      ),
      child: Row(
        children: [
          // Cincin progres rata-rata semua target aktif.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: rata),
            duration: 1000.ms,
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.pal.card,
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: context.pal.border,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${(v * 100).round()}%',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: context.pal.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kamu sudah $persen% lebih dekat dengan tujuanmu!',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGambar(TargetModel target) {
    final url = target.imageUrl;
    final fallback = Icon(
      Icons.savings_outlined,
      color: AppColors.primaryDark,
      size: 28,
    );

    Widget isi;
    if (url == null || url.isEmpty) {
      isi = fallback;
    } else if (url.startsWith('emoji:')) {
      isi = Center(
        child: Text(url.substring(6), style: const TextStyle(fontSize: 30)),
      );
    } else {
      isi = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, _) => const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, _, _) => fallback,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 60,
        height: 60,
        color: AppColors.primaryLight,
        child: isi,
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTargetCard(
    BuildContext context,
    WidgetRef ref,
    TargetModel target,
  ) {
    final pal = context.pal;
    final warna = target.progress >= 0.75
        ? AppColors.success
        : AppColors.primary;
    final status = _statusDeadline(context, target);
    final saran = _saranTabung(target);
    final tercapai = target.masihBerjalan && target.sudahTercapai;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: tercapai ? AppColors.primary : pal.outline,
            width: tercapai ? 1.5 : 0.5,
          ),
          boxShadow: tercapai
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGambar(target),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              target.title,
                              style: AppTextStyles.title.copyWith(fontSize: 16),
                            ),
                          ),
                          if (target.status == 'dibeli')
                            _statusChip('Dibeli', AppColors.success)
                          else if (target.status == 'dibatalkan')
                            _statusChip('Dibatalkan', pal.textSecondary),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (v) {
                              switch (v) {
                                case 'edit':
                                  _bukaEdit(context, target);
                                case 'riwayat':
                                  _bukaRiwayat(context, target);
                                case 'hapus':
                                  _hapusBerjalan(context, ref, target);
                                case 'tarik':
                                  _bukaTarik(context, target);
                              }
                            },
                            itemBuilder: (_) => [
                              if (target.masihBerjalan)
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                              const PopupMenuItem(
                                value: 'riwayat',
                                child: Text('Riwayat setoran'),
                              ),
                              if (target.masihBerjalan)
                                const PopupMenuItem(
                                  value: 'hapus',
                                  child: Text('Hapus'),
                                ),
                              if (target.masihBerjalan &&
                                  target.currentAmount > 0)
                                const PopupMenuItem(
                                  value: 'tarik',
                                  child: Text('Tarik dana'),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatRupiah(target.currentAmount)} / ${formatRupiah(target.targetAmount)}',
                        style: AppTextStyles.caption,
                      ),
                      if (target.deadline != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: pal.outline,
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event,
                                      size: 12,
                                      color: pal.primaryDark,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat(
                                        'd MMM yyyy',
                                        'id_ID',
                                      ).format(target.deadline!),
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              if (status != null)
                                Text(
                                  status.teks,
                                  style: AppTextStyles.caption.copyWith(
                                    color: status.warna,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: target.progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 10,
                        backgroundColor: pal.border,
                        color: warna,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(v * 100).round()}%',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                      color: warna,
                    ),
                  ),
                ],
              ),
            ),
            if (saran != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: pal.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 14,
                      color: pal.primaryDark,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(saran, style: AppTextStyles.caption)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: target.masihBerjalan
                  ? (target.sudahTercapai
                        ? PressableScale(
                                scale: .95,
                                child: FilledButton.icon(
                                  onPressed: () =>
                                      _bukaDialogTercapai(context, ref, target),
                                  icon: const Icon(
                                    Icons.celebration_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Target Tercapai! 🎉'),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .shimmer(
                                delay: 1400.ms,
                                duration: 1200.ms,
                                color: Colors.white54,
                              )
                        : PressableScale(
                            scale: .95,
                            child: TextButton.icon(
                              onPressed: () =>
                                  _bukaFormTambahDana(context, ref, target),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 18,
                              ),
                              label: const Text('Tambah Dana'),
                            ),
                          ))
                  : TextButton.icon(
                      onPressed: () => _konfirmasiHapus(context, ref, target),
                      icon: Icon(
                        Icons.delete_outline,
                        color: pal.error,
                        size: 18,
                      ),
                      label: Text('Hapus', style: TextStyle(color: pal.error)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// FORM TARGET BARU
// ================================================================

class _TargetFormSheet extends ConsumerStatefulWidget {
  const _TargetFormSheet();

  @override
  ConsumerState<_TargetFormSheet> createState() => _TargetFormSheetState();
}

class _TargetFormSheetState extends ConsumerState<_TargetFormSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _picker = ImagePicker();
  DateTime? _deadline;
  File? _gambar;
  String? _emoji;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pilihGambar() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (x != null) {
      setState(() {
        _gambar = File(x.path);
        _emoji = null;
      });
    }
  }

  Future<void> _pilihDeadline() async {
    final hasil = await pilihTanggalApp(context, first: DateTime.now());
    if (hasil != null) setState(() => _deadline = hasil);
  }

  Future<void> _simpan() async {
    final title = _titleController.text.trim();
    final amount =
        double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan nominal target wajib diisi.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(targetRepositoryProvider);
      final imageUrl = _gambar != null
          ? await repo.uploadGambar(_gambar!)
          : (_emoji != null ? 'emoji:$_emoji' : null);

      await repo.addTarget(
        TargetModel(
          id: '',
          title: title,
          targetAmount: amount,
          currentAmount: 0,
          deadline: _deadline,
          imageUrl: imageUrl,
        ),
      );
      ref.invalidate(targetsProvider);

      if (!mounted) return;
      await tawarkanNotif(context, ref, JenisReminder.nabung);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan target: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: 'Target Baru',
      subtitle: 'Tetapkan tujuan tabunganmu',
      icon: Icons.flag_rounded,

      children: [
        TargetImagePicker(
          foto: _gambar == null ? null : FileImage(_gambar!),
          emoji: _emoji,
          onUpload: _pilihGambar,
          onEmoji: (e) => setState(() {
            _emoji = e;
            if (e != null) _gambar = null;
          }),
          onClear: () => setState(() {
            _gambar = null;
            _emoji = null;
          }),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          decoration: appInput('Nama target', icon: Icons.flag_outlined),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [RupiahInputFormatter()],
          decoration: appInput(
            'Nominal target',
            prefix: 'Rp ',
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(height: 12),
        DateField(
          label: 'Tenggat waktu',
          hint: 'Tanpa batas waktu (opsional)',
          value: _deadline,
          onTap: _pilihDeadline,
          onClear: () => setState(() => _deadline = null),
        ),
        const SizedBox(height: 20),
        PrimaryButton(text: 'Simpan', loading: _saving, onPressed: _simpan),
      ],
    );
  }
}
// ================================================================
// FORM TAMBAH DANA
// ================================================================

class _TambahDanaSheet extends ConsumerStatefulWidget {
  final TargetModel target;

  const _TambahDanaSheet({required this.target});

  @override
  ConsumerState<_TambahDanaSheet> createState() => _TambahDanaSheetState();
}

class _TambahDanaSheetState extends ConsumerState<_TambahDanaSheet> {
  final _amountController = TextEditingController();
  bool _saving = false;

  String? _walletId;

  double get _amount =>
      double.tryParse(
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      ) ??
      0;

  void _tambah(double n) {
    final baru = formatRibuan(_amount + n);
    _amountController.value = TextEditingValue(
      text: baru,
      selection: TextSelection.collapsed(offset: baru.length),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_walletId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih sumber dana dulu.')));
      return;
    }

    final amount =
        double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0.')),
      );
      return;
    }

    setState(() => _saving = true);

    final baruTercapai =
        !widget.target.sudahTercapai &&
        widget.target.currentAmount + amount >= widget.target.targetAmount;
    final overlay = Overlay.of(context, rootOverlay: true);

    try {
      // Proses setoran cukup dilakukan satu kali.
      await ref
          .read(targetRepositoryProvider)
          .tambahDana(widget.target, amount, _walletId!);

      ref.invalidate(targetsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(targetDepositsProvider(widget.target.id));

      if (!mounted) return;
      Navigator.pop(context);

      if (baruTercapai) {
        tampilkanConfetti(overlay);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menambah dana: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = widget.target;
    final sisa = (t.targetAmount - t.currentAmount)
        .clamp(0.0, double.infinity)
        .toDouble();
    final baru = t.targetAmount <= 0
        ? 0.0
        : ((t.currentAmount + _amount) / t.targetAmount)
              .clamp(0.0, 1.0)
              .toDouble();
    final tercapai = _amount > 0 && t.currentAmount + _amount >= t.targetAmount;

    return SheetFrame(
      title: 'Tambah Dana',
      subtitle: t.title,
      icon: Icons.savings_outlined,
      children: [
        TextField(
          controller: _amountController,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [RupiahInputFormatter()],
          onChanged: (_) => setState(() {}),
          decoration: appInput(
            'Nominal',
            prefix: 'Rp ',
            icon: Icons.savings_outlined,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in [10000, 50000, 100000])
              QuickChip(
                label: '+${n ~/ 1000}rb',
                onTap: () => _tambah(n.toDouble()),
              ),
            if (sisa > 0)
              QuickChip(
                label: 'Pas target',
                onTap: () {
                  _amountController.text = formatRibuan(sisa);
                  setState(() {});
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedContainer(
          duration: 250.ms,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tercapai
                ? AppColors.success.withValues(alpha: 0.12)
                : pal.primaryLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: tercapai ? AppColors.success : pal.outline,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: 200.ms,
                child: Text(
                  tercapai
                      ? 'Target akan tercapai! 🎉'
                      : 'Progres setelah setoran',
                  key: ValueKey(tercapai),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tercapai ? AppColors.success : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(end: baru),
                duration: 400.ms,
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: v,
                          minHeight: 10,
                          backgroundColor: pal.border,
                          color: tercapai
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(v * 100).round()}%',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Consumer(
          builder: (context, ref, _) {
            final walletsAsync = ref.watch(walletsProvider);
            return walletsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Gagal memuat wallet: $e'),
              data: (wallets) {
                if (wallets.isEmpty) {
                  return Text(
                    'Belum ada wallet. Buat dulu di halaman Akun.',
                    style: AppTextStyles.caption,
                  );
                }
                _walletId ??= wallets.first.id;
                return WalletChipPicker(
                  label: 'Ambil dari',
                  wallets: wallets,
                  selectedId: _walletId,
                  onChanged: (id) => setState(() => _walletId = id),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
        PrimaryButton(text: 'Simpan', loading: _saving, onPressed: _simpan),
      ],
    );
  }
}
