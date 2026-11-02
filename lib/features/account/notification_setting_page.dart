import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../shared/models/notification_settings_model.dart';
import '../../features/notification/notification_service.dart';
import '../../features/notification/notification_provider.dart';
import '../notification/notification_prompt.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  NotificationSettingsModel? _lokal;

  Future<void> _simpan(
    NotificationSettingsModel baru, {
    bool menyalakan = false,
  }) async {
    final lama = _lokal ?? ref.read(notificationSettingsProvider).value;

    // Optimistic update: langsung ubah tampilan
    setState(() {
      _lokal = baru;
    });

    try {
      // Jika switch dinyalakan, pastikan izin notifikasi tersedia
      if (menyalakan) {
        final izin = await NotificationService.instance.pastikanIzin();

        if (!izin) {
          throw Exception('Izin notifikasi ditolak');
        }
      }

      // Simpan pengaturan
      await ref.read(notificationRepositoryProvider).saveSettings(baru);

      // Refresh dulu supaya jadwal memakai pengaturan yang baru disimpan
      ref.invalidate(notificationSettingsProvider);

      // Jadwalkan ulang semua notifikasi
      await jadwalkanUlangSemua(ref);

      // Refresh provider
      ref.invalidate(notificationSettingsProvider);
      await jadwalkanUlangSemua(ref);
    } catch (e) {
      debugPrint('Gagal menyimpan pengaturan notifikasi: $e');

      if (!mounted) return;

      // Kembalikan nilai sebelumnya jika gagal
      setState(() {
        _lokal = lama;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Izin')
                ? 'Izin notifikasi ditolak. Aktifkan di Pengaturan HP.'
                : 'Gagal menyimpan pengaturan notifikasi.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi'), centerTitle: true),
      body: settingsAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (e, _) {
          return Center(child: Text('Gagal memuat: $e'));
        },
        data: (server) {
          final s = _lokal ?? server;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _switchTile(
                'Pengingat Catat Keuangan',
                'Jam 20:00 jika 3 hari belum mencatat',
                s.reminderCatatAktif,
                (v) {
                  _simpan(s.copyWith(reminderCatatAktif: v), menyalakan: v);
                },
              ),

              _switchTile(
                'Pengingat Tagihan',
                'Jam 09:00 sehari sebelum jatuh tempo',
                s.reminderTagihanAktif,
                (v) {
                  _simpan(s.copyWith(reminderTagihanAktif: v), menyalakan: v);
                },
              ),

              _switchTile(
                'Pengingat Menabung',
                'Setiap hari jam 19:00',
                s.reminderNabungAktif,
                (v) {
                  _simpan(s.copyWith(reminderNabungAktif: v), menyalakan: v);
                },
              ),

              _switchTile(
                'Pengingat Budget',
                'Jam 20:00 jika ada kategori di atas 80% limit',
                s.reminderBudgetAktif,
                (v) {
                  _simpan(s.copyWith(reminderBudgetAktif: v), menyalakan: v);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _switchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
