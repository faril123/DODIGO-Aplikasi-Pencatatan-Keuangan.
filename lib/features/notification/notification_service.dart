import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../shared/models/bill_model.dart';
import '../../shared/models/budget_model.dart';
import '../../shared/models/notification_settings_model.dart';
import '../../shared/models/transaction_model.dart';
import '../../core/utils/formatters.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ============================================================
  // NOTIFICATION IDS
  // ============================================================

  static const int _reminderCatatId = 1;
  static const int _tagihanIdAwal = 100; // 100, 101, 102, ... satu per tagihan
  static const int _reminderNabungId = 3;
  static const int _reminderBudgetId = 4;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings();

    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<bool> pastikanIzin() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    if (await android.areNotificationsEnabled() ?? false) return true;
    return await android.requestNotificationsPermission() ?? false;
  }
  // ============================================================
  // NOTIFICATION DETAILS
  // ============================================================

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'dodigi_reminders',
      'Pengingat DODIGI',
      channelDescription: 'Pengingat keuangan dari DODIGI',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  // ============================================================
  // CANCEL SCHEDULE
  // ============================================================

  Future<void> _hapusJadwal(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> _hapusSemuaJadwal() async {
    await _plugin.cancelAll();
  }

  // ============================================================
  // DAILY NOTIFICATION
  // ============================================================

  Future<void> _jadwalkanHarian({
    required int id,
    required String judul,
    required String isi,
    required int jam,
    required int menit,
  }) async {
    await _hapusJadwal(id);

    final now = tz.TZDateTime.now(tz.local);

    var waktu = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      jam,
      menit,
    );

    if (waktu.isBefore(now)) {
      waktu = waktu.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: judul,
      body: isi,
      scheduledDate: waktu,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ============================================================
  // ONE TIME NOTIFICATION
  // ============================================================

  Future<void> _jadwalkanSekali({
    required int id,
    required String judul,
    required String isi,
    required tz.TZDateTime waktu,
  }) async {
    await _hapusJadwal(id);

    final now = tz.TZDateTime.now(tz.local);

    if (waktu.isBefore(now)) {
      return;
    }

    await _plugin.zonedSchedule(
      id: id,
      title: judul,
      body: isi,
      scheduledDate: waktu,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // ============================================================
  // CHECK TRANSACTION
  // ============================================================

  bool _adaTransaksiDalam3Hari(List<TransactionModel> transaksi) {
    if (transaksi.isEmpty) {
      return false;
    }

    final now = DateTime.now();

    final hariIni = DateTime(now.year, now.month, now.day);

    return transaksi.any((t) {
      final tanggalTransaksi = DateTime(
        t.transactionDate.year,
        t.transactionDate.month,
        t.transactionDate.day,
      );

      final selisihHari = hariIni.difference(tanggalTransaksi).inDays;

      return selisihHari >= 0 && selisihHari < 3;
    });
  }

  // ============================================================
  // CHECK TOMORROW'S BILLS
  // ============================================================

  List<({BillModel bill, tz.TZDateTime waktu, bool hariH})> _jadwalTagihan(
    List<BillModel> tagihan,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    final hasil = <({BillModel bill, tz.TZDateTime waktu, bool hariH})>[];

    for (final bill in tagihan) {
      if (bill.isPaid) continue;
      final d = bill.dueDate;
      final hMin1 = tz.TZDateTime(tz.local, d.year, d.month, d.day - 1, 9);
      final hariH = tz.TZDateTime(tz.local, d.year, d.month, d.day, 9);

      if (hMin1.isAfter(now)) {
        hasil.add((bill: bill, waktu: hMin1, hariH: false));
      } else if (hariH.isAfter(now)) {
        hasil.add((bill: bill, waktu: hariH, hariH: true));
      }
    }

    hasil.sort((a, b) => a.waktu.compareTo(b.waktu));
    return hasil.take(30).toList(); // batasi supaya aman dari limit OS
  }

  // ============================================================
  // SCHEDULE ALL NOTIFICATIONS
  // ============================================================

  ({String judul, String isi})? _ringkasBudget(
    List<BudgetModel> budgets,
    Map<String, double> pengeluaran,
  ) {
    final over = <String>[];
    final hampir = <String>[];
    for (final b in budgets) {
      if (b.limitAmount <= 0) continue;
      final terpakai = pengeluaran[b.category] ?? 0;
      if (terpakai > b.limitAmount) {
        over.add(b.category);
      } else if (terpakai >= b.limitAmount * 0.8) {
        hampir.add(b.category);
      }
    }
    if (over.isNotEmpty) {
      return (
        judul: 'Budget melebihi limit ⚠️',
        isi:
            'Melebihi limit: ${over.join(', ')}'
            '${hampir.isEmpty ? '' : '. Hampir habis: ${hampir.join(', ')}'}',
      );
    }
    if (hampir.isNotEmpty) {
      return (
        judul: 'Budget hampir habis 🟠',
        isi: 'Sudah lebih dari 80%: ${hampir.join(', ')}',
      );
    }
    return null;
  }

  Future<void> jadwalkanSemua({
    required NotificationSettingsModel settings,
    required List<TransactionModel> transaksi,
    required List<BillModel> tagihan,
    List<BudgetModel> budgets = const [],
    Map<String, double> pengeluaran = const {},
  }) async {
    await init();

    // Hapus semua jadwal lama terlebih dahulu.
    await _hapusSemuaJadwal();

    // ==========================================================
    // 1. REMINDER CATAT TRANSAKSI
    // ==========================================================

    if (settings.reminderCatatAktif) {
      final adaTransaksiDalam3Hari = _adaTransaksiDalam3Hari(transaksi);

      if (!adaTransaksiDalam3Hari) {
        await _jadwalkanHarian(
          id: _reminderCatatId,
          judul: 'Jangan lupa catat keuangan 📝',
          isi:
              'Sudah 3 hari belum ada catatan transaksi. Yuk catat lagi di DODIGI!',
          jam: 20,
          menit: 0,
        );
      }
    }

    // ==========================================================
    // 2. REMINDER TAGIHAN
    // ==========================================================

    if (settings.reminderTagihanAktif) {
      final jadwal = _jadwalTagihan(tagihan);
      for (var i = 0; i < jadwal.length; i++) {
        final j = jadwal[i];
        await _jadwalkanSekali(
          id: _tagihanIdAwal + i,
          judul: j.hariH
              ? 'Tagihan jatuh tempo hari ini 💳'
              : 'Tagihan jatuh tempo besok 💳',
          isi:
              'Jangan lupa bayar ${j.bill.title} (${formatRupiah(j.bill.amount)})',
          waktu: j.waktu,
        );
      }
    }
    // ==========================================================
    // 3. REMINDER NABUNG
    // ==========================================================

    if (settings.reminderNabungAktif) {
      await _jadwalkanHarian(
        id: _reminderNabungId,
        judul: 'Udah nabung belum nih? 🎯',
        isi: 'Targetmu nunggu tuh! Yuk sisihkan sedikit uang hari ini.',
        jam: 19,
        menit: 0,
      );
    }

    // 4. REMINDER BUDGET
    if (settings.reminderBudgetAktif) {
      final ringkas = _ringkasBudget(budgets, pengeluaran);
      if (ringkas != null) {
        final now = tz.TZDateTime.now(tz.local);
        var waktu = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);
        if (!waktu.isAfter(now)) {
          waktu = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, 9);
        }
        await _jadwalkanSekali(
          id: _reminderBudgetId,
          judul: ringkas.judul,
          isi: ringkas.isi,
          waktu: waktu,
        );
      }
    }
  }
}
