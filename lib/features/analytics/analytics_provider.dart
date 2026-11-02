import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../transaction/transaction_provider.dart';

enum Periode { minggu, bulan, tahun }

final periodeAnalitikProvider = StateProvider<Periode>((ref) => Periode.minggu);

final offsetPeriodeProvider = StateProvider<int>((ref) => 0);

class RentangWaktu {
  final DateTime awal;
  final DateTime akhir;

  const RentangWaktu(this.awal, this.akhir);
}

/// Mengambil transaksi pertama user.
final transaksiPertamaProvider = Provider.autoDispose<DateTime?>((ref) {
  final transaksi = ref.watch(transactionsProvider).valueOrNull ?? [];

  if (transaksi.isEmpty) return null;

  DateTime pertama = transaksi.first.transactionDate;

  for (final t in transaksi) {
    if (t.transactionDate.isBefore(pertama)) {
      pertama = t.transactionDate;
    }
  }

  return pertama;
});

/// Menentukan offset maksimum berdasarkan transaksi pertama.
///
/// Contoh:
/// - transaksi pertama Oktober 2026
/// - sekarang Oktober 2026
/// -> maxOffset = 0
///
/// Kalau sekarang Desember 2026:
/// -> Bulan: maxOffset = 2
/// -> Tahun: maxOffset = 0
///
/// Jadi user tidak bisa navigasi ke periode sebelum ada transaksi.
final maxOffsetPeriodeProvider = Provider.autoDispose<int>((ref) {
  final periode = ref.watch(periodeAnalitikProvider);
  final transaksiPertama = ref.watch(transaksiPertamaProvider);

  if (transaksiPertama == null) {
    return 0;
  }

  final now = DateTime.now();

  switch (periode) {
    case Periode.minggu:
      final mingguSekarang = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));

      final mingguPertama = DateTime(
        transaksiPertama.year,
        transaksiPertama.month,
        transaksiPertama.day,
      ).subtract(Duration(days: transaksiPertama.weekday - 1));

      return mingguSekarang.difference(mingguPertama).inDays ~/ 7;

    case Periode.bulan:
      return (now.year - transaksiPertama.year) * 12 +
          (now.month - transaksiPertama.month);

    case Periode.tahun:
      return now.year - transaksiPertama.year;
  }
});

RentangWaktu _rentangDenganOffset(Periode periode, int offset) {
  final now = DateTime.now();

  switch (periode) {
    case Periode.minggu:
      final senin = now.subtract(
        Duration(days: now.weekday - 1 + (offset * 7)),
      );

      final awal = DateTime(senin.year, senin.month, senin.day);

      return RentangWaktu(awal, awal.add(const Duration(days: 7)));

    case Periode.bulan:
      final awal = DateTime(now.year, now.month - offset);

      final akhir = DateTime(now.year, now.month - offset + 1);

      return RentangWaktu(awal, akhir);

    case Periode.tahun:
      return RentangWaktu(
        DateTime(now.year - offset),
        DateTime(now.year - offset + 1),
      );
  }
}

final labelPeriodeAktifProvider = Provider.autoDispose<String>((ref) {
  final periode = ref.watch(periodeAnalitikProvider);
  final offset = ref.watch(offsetPeriodeProvider);

  final rentang = _rentangDenganOffset(periode, offset);

  const bulanNama = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Juni',
    'Juli',
    'Agus',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  switch (periode) {
    case Periode.minggu:
      final akhirMinggu = rentang.akhir.subtract(const Duration(days: 1));

      // Kalau minggu melewati bulan, tampilkan bulan awal dan akhir.
      if (rentang.awal.month != akhirMinggu.month) {
        return '${rentang.awal.day} ${bulanNama[rentang.awal.month - 1]} - '
            '${akhirMinggu.day} ${bulanNama[akhirMinggu.month - 1]}';
      }

      return '${rentang.awal.day} - '
          '${akhirMinggu.day} '
          '${bulanNama[akhirMinggu.month - 1]}';

    case Periode.bulan:
      return '${bulanNama[rentang.awal.month - 1]} '
          '${rentang.awal.year}';

    case Periode.tahun:
      return '${rentang.awal.year}';
  }
});

final totalPengeluaranPeriodeProvider = Provider.autoDispose<double>((ref) {
  final periode = ref.watch(periodeAnalitikProvider);
  final offset = ref.watch(offsetPeriodeProvider);

  final transaksi = ref.watch(transactionsProvider).valueOrNull ?? [];

  final rentang = _rentangDenganOffset(periode, offset);

  return transaksi
      .where(
        (t) =>
            t.amount < 0 &&
            !t.transactionDate.isBefore(rentang.awal) &&
            t.transactionDate.isBefore(rentang.akhir),
      )
      .fold(0.0, (sum, t) => sum + t.amount.abs());
});

class TitikTren {
  final String label;
  final double nilai;
  final bool hariIni;

  const TitikTren(this.label, this.nilai, {this.hariIni = false});
}

final trenPeriodeProvider = Provider.autoDispose<List<TitikTren>>((ref) {
  final periode = ref.watch(periodeAnalitikProvider);
  final offset = ref.watch(offsetPeriodeProvider);

  final transaksi = ref.watch(transactionsProvider).valueOrNull ?? [];

  final now = DateTime.now();

  final acuan = switch (periode) {
    Periode.minggu => now.subtract(Duration(days: offset * 7)),
    Periode.bulan => DateTime(now.year, now.month - offset),
    Periode.tahun => DateTime(now.year - offset),
  };

  switch (periode) {
    case Periode.minggu:
      final senin = acuan.subtract(Duration(days: acuan.weekday - 1));

      final labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

      return List.generate(7, (i) {
        final tanggal = DateTime(senin.year, senin.month, senin.day + i);

        final total = transaksi
            .where(
              (t) =>
                  t.amount < 0 &&
                  t.transactionDate.year == tanggal.year &&
                  t.transactionDate.month == tanggal.month &&
                  t.transactionDate.day == tanggal.day,
            )
            .fold(0.0, (sum, t) => sum + t.amount.abs());

        return TitikTren(
          labels[i],
          total,
          hariIni:
              offset == 0 &&
              tanggal.year == now.year &&
              tanggal.month == now.month &&
              tanggal.day == now.day,
        );
      });

    case Periode.bulan:
      final jumlahHari = DateTime(acuan.year, acuan.month + 1, 0).day;

      final jumlahMinggu = (jumlahHari / 7).ceil();

      return List.generate(jumlahMinggu, (i) {
        final mulai = i * 7 + 1;

        final selesai = ((i + 1) * 7).clamp(0, jumlahHari);

        final total = transaksi
            .where(
              (t) =>
                  t.amount < 0 &&
                  t.transactionDate.year == acuan.year &&
                  t.transactionDate.month == acuan.month &&
                  t.transactionDate.day >= mulai &&
                  t.transactionDate.day <= selesai,
            )
            .fold(0.0, (sum, t) => sum + t.amount.abs());

        final sedangBerjalan =
            offset == 0 && now.day >= mulai && now.day <= selesai;

        return TitikTren('M${i + 1}', total, hariIni: sedangBerjalan);
      });

    case Periode.tahun:
      const labels = [
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

      return List.generate(12, (i) {
        final bulan = i + 1;

        final total = transaksi
            .where(
              (t) =>
                  t.amount < 0 &&
                  t.transactionDate.year == acuan.year &&
                  t.transactionDate.month == bulan,
            )
            .fold(0.0, (sum, t) => sum + t.amount.abs());

        return TitikTren(
          labels[i],
          total,
          hariIni: offset == 0 && bulan == now.month,
        );
      });
  }
});

class KategoriRingkasan {
  final String nama;
  final double nominal;
  final double persen;

  const KategoriRingkasan(this.nama, this.nominal, this.persen);
}

final kategoriTerbanyakProvider = Provider.autoDispose<List<KategoriRingkasan>>(
  (ref) {
    final periode = ref.watch(periodeAnalitikProvider);
    final offset = ref.watch(offsetPeriodeProvider);

    final transaksi = ref.watch(transactionsProvider).valueOrNull ?? [];

    final rentang = _rentangDenganOffset(periode, offset);

    final Map<String, double> perKategori = {};

    for (final t in transaksi.where(
      (t) =>
          t.amount < 0 &&
          !t.transactionDate.isBefore(rentang.awal) &&
          t.transactionDate.isBefore(rentang.akhir),
    )) {
      perKategori[t.category] = (perKategori[t.category] ?? 0) + t.amount.abs();
    }

    final total = perKategori.values.fold(0.0, (a, b) => a + b);

    final list = perKategori.entries
        .map(
          (e) => KategoriRingkasan(
            e.key,
            e.value,
            total <= 0 ? 0 : e.value / total * 100,
          ),
        )
        .toList();

    list.sort((a, b) => b.nominal.compareTo(a.nominal));

    return list;
  },
);

class DistribusiSlice {
  final String nama;
  final double nominal;
  final double persen;

  const DistribusiSlice(this.nama, this.nominal, this.persen);
}

/// Top 2 kategori + sisanya digabung menjadi "Lainnya".
final distribusiDonutProvider = Provider.autoDispose<List<DistribusiSlice>>((
  ref,
) {
  final kategori = ref.watch(kategoriTerbanyakProvider);

  if (kategori.isEmpty) return [];

  final total = kategori.fold(0.0, (sum, k) => sum + k.nominal);

  final teratas = kategori.take(2).toList();

  final sisaNominal = kategori.skip(2).fold(0.0, (sum, k) => sum + k.nominal);

  final hasil = teratas
      .map(
        (k) => DistribusiSlice(
          k.nama,
          k.nominal,
          total <= 0 ? 0 : k.nominal / total * 100,
        ),
      )
      .toList();

  if (sisaNominal > 0) {
    hasil.add(
      DistribusiSlice(
        'Lainnya',
        sisaNominal,
        total <= 0 ? 0 : sisaNominal / total * 100,
      ),
    );
  }

  return hasil;
});

class InsightAnalitik {
  final String pesan;
  final bool positif;

  const InsightAnalitik(this.pesan, this.positif);
}

final insightAnalitikProvider = Provider.autoDispose<InsightAnalitik>((ref) {
  final periode = ref.watch(periodeAnalitikProvider);
  final offset = ref.watch(offsetPeriodeProvider);

  final transaksi = ref.watch(transactionsProvider).valueOrNull ?? [];

  final rentangIni = _rentangDenganOffset(periode, offset);

  final rentangLalu = _rentangDenganOffset(periode, offset + 1);

  final totalIni = transaksi
      .where(
        (t) =>
            t.amount < 0 &&
            !t.transactionDate.isBefore(rentangIni.awal) &&
            t.transactionDate.isBefore(rentangIni.akhir),
      )
      .fold(0.0, (sum, t) => sum + t.amount.abs());

  final totalLalu = transaksi
      .where(
        (t) =>
            t.amount < 0 &&
            !t.transactionDate.isBefore(rentangLalu.awal) &&
            t.transactionDate.isBefore(rentangLalu.akhir),
      )
      .fold(0.0, (sum, t) => sum + t.amount.abs());

  final labelPeriode = switch (periode) {
    Periode.minggu => 'minggu',
    Periode.bulan => 'bulan',
    Periode.tahun => 'tahun',
  };

  if (totalLalu <= 0) {
    return InsightAnalitik(
      'Belum ada data $labelPeriode lalu untuk dibandingkan.',
      true,
    );
  }

  final perubahan = ((totalIni - totalLalu) / totalLalu) * 100;

  if (perubahan <= 0) {
    return InsightAnalitik(
      'Pengeluaran kamu turun '
      '${perubahan.abs().toStringAsFixed(0)}% '
      'dibanding $labelPeriode lalu. '
      'Teruskan kebiasaan baik ini!',
      true,
    );
  } else {
    return InsightAnalitik(
      'Pengeluaran kamu naik '
      '${perubahan.toStringAsFixed(0)}% '
      'dibanding $labelPeriode lalu. '
      'Coba lebih hemat $labelPeriode ini.',
      false,
    );
  }
});
