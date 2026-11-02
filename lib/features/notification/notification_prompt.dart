import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/models/notification_settings_model.dart';
import '../Financial_Tools_Menu/Budget/budget_provider.dart';
import '../Financial_Tools_Menu/Tagihan/tagihan_provider.dart';
import '../transaction/transaction_provider.dart';
import 'notification_provider.dart';
import 'notification_service.dart';

enum JenisReminder { catat, tagihan, nabung, budget }

Future<void> tawarkanNotif(
  BuildContext context,
  WidgetRef ref,
  JenisReminder jenis,
) async {
  final s = await ref.read(notificationSettingsProvider.future);
  final sudahAktif = switch (jenis) {
    JenisReminder.catat => s.reminderCatatAktif,
    JenisReminder.tagihan => s.reminderTagihanAktif,
    JenisReminder.nabung => s.reminderNabungAktif,
    JenisReminder.budget => s.reminderBudgetAktif,
  };

  if (!context.mounted) return;

  if (sudahAktif) {
    await _jalankanJadwal(ref, s);
    return;
  }

  final (judul, isi) = switch (jenis) {
    JenisReminder.catat => (
      'Aktifkan pengingat catat keuangan?',
      'Kami ingatkan jam 20:00 kalau 3 hari belum mencatat transaksi.',
    ),
    JenisReminder.tagihan => (
      'Aktifkan pengingat tagihan?',
      'Kami ingatkan jam 09:00 sehari sebelum tagihan jatuh tempo.',
    ),
    JenisReminder.nabung => (
      'Aktifkan pengingat menabung?',
      'Kami ingatkan tiap hari jam 19:00 supaya targetmu tercapai.',
    ),
    JenisReminder.budget => (
      'Aktifkan pengingat budget?',
      'Kami ingatkan kalau pengeluaran suatu kategori sudah lebih dari 80% limit atau melebihinya.',
    ),
  };

  final setuju = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(judul),
      content: Text(isi),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Nanti'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Aktifkan',
            style: TextStyle(color: AppColors.primaryDark),
          ),
        ),
      ],
    ),
  );
  if (setuju != true) return;

  final izin = await NotificationService.instance.pastikanIzin();
  if (!izin) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin notifikasi belum diberikan. Buka Pengaturan HP → Aplikasi → DODIGI → Notifikasi.',
          ),
        ),
      );
    }
    return;
  }

  final baru = switch (jenis) {
    JenisReminder.catat => s.copyWith(reminderCatatAktif: true),
    JenisReminder.tagihan => s.copyWith(reminderTagihanAktif: true),
    JenisReminder.nabung => s.copyWith(reminderNabungAktif: true),
    JenisReminder.budget => s.copyWith(reminderBudgetAktif: true),
  };

  await ref.read(notificationRepositoryProvider).saveSettings(baru);
  ref.invalidate(notificationSettingsProvider);

  await _jalankanJadwal(ref, baru);
}

/// Kumpulkan data terbaru lalu jadwalkan semua reminder.
Future<void> _jalankanJadwal(WidgetRef ref, NotificationSettingsModel s) async {
  final transaksi = await ref.read(transactionsProvider.future);
  final tagihan = await ref.read(billsProvider.future);
  final budgets = await ref.read(budgetsProvider.future);
  final pengeluaran = ref.read(pengeluaranPerKategoriProvider);
  await NotificationService.instance.jadwalkanSemua(
    settings: s,
    transaksi: transaksi,
    tagihan: tagihan,
    budgets: budgets,
    pengeluaran: pengeluaran,
  );
}

/// Jadwalkan ulang semua reminder tanpa dialog.
/// Gagal menjadwalkan tidak boleh membuat aksi utama terlihat gagal.
Future<void> jadwalkanUlangSemua(WidgetRef ref) async {
  try {
    final s = await ref.read(notificationSettingsProvider.future);
    await _jalankanJadwal(ref, s);
  } catch (_) {}
}

/// Nama lama, dipertahankan supaya pemanggil di Tagihan tidak perlu diubah.
Future<void> jadwalkanUlangTagihan(WidgetRef ref) => jadwalkanUlangSemua(ref);
