import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/transaction_model.dart';
import '../../transaction/transaction_provider.dart';

enum PeriodeLaporan { minggu, bulan, tahun, kustom }

final periodeLaporanProvider = StateProvider<PeriodeLaporan>(
  (ref) => PeriodeLaporan.bulan,
);

/// Rentang yang dipilih lewat "Pilih Tanggal".
final rentangKustomProvider = StateProvider<DateTimeRange?>((ref) => null);

/// Tanggal acuan untuk periode mingguan/bulanan/tahunan.
final jangkarLaporanProvider = StateProvider<DateTime>((ref) => DateTime.now());

class RentangLaporan {
  final DateTime mulai;
  final DateTime akhir; // eksklusif
  final DateTime mulaiSebelum;
  final DateTime akhirSebelum; // eksklusif
  final String labelBanding;

  const RentangLaporan({
    required this.mulai,
    required this.akhir,
    required this.mulaiSebelum,
    required this.akhirSebelum,
    required this.labelBanding,
  });

  int get jumlahHari => akhir.difference(mulai).inDays;
}

final rentangLaporanProvider = Provider.autoDispose<RentangLaporan>((ref) {
  final periode = ref.watch(periodeLaporanProvider);
  final kustom = ref.watch(rentangKustomProvider);
  final a = ref.watch(jangkarLaporanProvider);
  final now = DateTime.now();
  final hariIni = DateTime(now.year, now.month, now.day);
  final hariA = DateTime(a.year, a.month, a.day);

  switch (periode) {
    case PeriodeLaporan.minggu:
      final mulai = hariA.subtract(Duration(days: hariA.weekday - 1));
      return RentangLaporan(
        mulai: mulai,
        akhir: mulai.add(const Duration(days: 7)),
        mulaiSebelum: mulai.subtract(const Duration(days: 7)),
        akhirSebelum: mulai,
        labelBanding: 'minggu sebelumnya',
      );
    case PeriodeLaporan.bulan:
      final mulai = DateTime(a.year, a.month);
      return RentangLaporan(
        mulai: mulai,
        akhir: DateTime(a.year, a.month + 1),
        mulaiSebelum: DateTime(a.year, a.month - 1),
        akhirSebelum: mulai,
        labelBanding: 'bulan sebelumnya',
      );
    case PeriodeLaporan.tahun:
      final mulai = DateTime(a.year);
      return RentangLaporan(
        mulai: mulai,
        akhir: DateTime(a.year + 1),
        mulaiSebelum: DateTime(a.year - 1),
        akhirSebelum: mulai,
        labelBanding: 'tahun sebelumnya',
      );
    case PeriodeLaporan.kustom:
      final r =
          kustom ??
          DateTimeRange(start: DateTime(now.year, now.month), end: hariIni);
      final mulai = DateTime(r.start.year, r.start.month, r.start.day);
      final akhir = DateTime(r.end.year, r.end.month, r.end.day + 1);
      return RentangLaporan(
        mulai: mulai,
        akhir: akhir,
        mulaiSebelum: mulai.subtract(akhir.difference(mulai)),
        akhirSebelum: mulai,
        labelBanding: 'periode sebelumnya',
      );
  }
});

List<TransactionModel> _dalam(
  List<TransactionModel> semua,
  DateTime mulai,
  DateTime akhir,
) {
  return semua.where((t) {
    final d = t.transactionDate;
    return !d.isBefore(mulai) && d.isBefore(akhir);
  }).toList();
}

final transaksiLaporanProvider = Provider.autoDispose<List<TransactionModel>>((
  ref,
) {
  final r = ref.watch(rentangLaporanProvider);
  final semua = ref.watch(transactionsProvider).valueOrNull ?? [];
  return _dalam(semua, r.mulai, r.akhir);
});

final ringkasanLaporanProvider =
    Provider.autoDispose<({double pemasukan, double pengeluaran})>((ref) {
      final transaksi = ref.watch(transaksiLaporanProvider);
      final pemasukan = transaksi
          .where((t) => t.amount > 0)
          .fold(0.0, (sum, t) => sum + t.amount);
      final pengeluaran = transaksi
          .where((t) => t.amount < 0)
          .fold(0.0, (sum, t) => sum + t.amount.abs());
      return (pemasukan: pemasukan, pengeluaran: pengeluaran);
    });

/// Total pengeluaran pada periode pembanding (minggu/bulan/tahun lalu).
final pengeluaranSebelumnyaProvider = Provider.autoDispose<double>((ref) {
  final r = ref.watch(rentangLaporanProvider);
  final semua = ref.watch(transactionsProvider).valueOrNull ?? [];
  return _dalam(
    semua,
    r.mulaiSebelum,
    r.akhirSebelum,
  ).where((t) => t.amount < 0).fold(0.0, (sum, t) => sum + t.amount.abs());
});

final pengeluaranPerKategoriLaporanProvider =
    Provider.autoDispose<List<MapEntry<String, double>>>((ref) {
      final transaksi = ref.watch(transaksiLaporanProvider);
      final Map<String, double> hasil = {};
      for (final t in transaksi.where((t) => t.amount < 0)) {
        hasil[t.category] = (hasil[t.category] ?? 0) + t.amount.abs();
      }
      final list = hasil.entries.toList();
      list.sort((a, b) => b.value.compareTo(a.value));
      return list;
    });

// ---------------- ARUS KAS (data grafik) ----------------

typedef TitikArusKas = ({String label, double masuk, double keluar});

const _hariSingkat = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _bulanSingkat = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Per hari (≤7 hari), per minggu (≤62 hari), selebihnya per bulan.
final arusKasLaporanProvider = Provider.autoDispose<List<TitikArusKas>>((ref) {
  final r = ref.watch(rentangLaporanProvider);
  final transaksi = ref.watch(transaksiLaporanProvider);
  final hari = r.jumlahHari;

  late final int jumlah;
  late final int Function(DateTime) indeks;
  late final String Function(int) label;

  if (hari <= 7) {
    jumlah = hari;
    indeks = (d) => d.difference(r.mulai).inDays;
    label = (i) => _hariSingkat[r.mulai.add(Duration(days: i)).weekday - 1];
  } else if (hari <= 62) {
    jumlah = (hari / 7).ceil();
    indeks = (d) => d.difference(r.mulai).inDays ~/ 7;
    label = (i) => 'M${i + 1}';
  } else {
    final terakhir = r.akhir.subtract(const Duration(days: 1));
    final dasar = r.mulai.year * 12 + r.mulai.month;
    jumlah = (terakhir.year * 12 + terakhir.month) - dasar + 1;
    indeks = (d) => (d.year * 12 + d.month) - dasar;
    label = (i) =>
        _bulanSingkat[DateTime(r.mulai.year, r.mulai.month + i).month - 1];
  }

  final masuk = List<double>.filled(jumlah, 0);
  final keluar = List<double>.filled(jumlah, 0);
  for (final t in transaksi) {
    final i = indeks(t.transactionDate);
    if (i < 0 || i >= jumlah) continue;
    if (t.amount > 0) {
      masuk[i] += t.amount;
    } else {
      keluar[i] += t.amount.abs();
    }
  }

  return List.generate(
    jumlah,
    (i) => (label: label(i), masuk: masuk[i], keluar: keluar[i]),
  );
});

/// Tanggal transaksi paling baru (null kalau belum pernah mencatat).
final transaksiTerakhirProvider = Provider.autoDispose<DateTime?>((ref) {
  final semua = ref.watch(transactionsProvider).valueOrNull ?? [];
  if (semua.isEmpty) return null;
  return semua
      .map((t) => t.transactionDate)
      .reduce((a, b) => a.isAfter(b) ? a : b);
});
