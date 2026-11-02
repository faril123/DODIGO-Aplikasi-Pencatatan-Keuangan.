import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text.dart';
import '../../../core/utils/category_style.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_palette.dart';

import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/header_line.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/widgets/app_form_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import 'laporan_provider.dart';

const _warnaPemasukan = Color(0xFFD9C3A5);

class LaporanPage extends ConsumerWidget {
  const LaporanPage({super.key});

  // ============================================================
  // AKSI & HELPER
  // ============================================================

  bool _isDefault(PeriodeLaporan p, DateTime a) {
    final now = DateTime.now();
    return p == PeriodeLaporan.bulan &&
        a.year == now.year &&
        a.month == now.month;
  }

  void _reset(WidgetRef ref) {
    ref.read(periodeLaporanProvider.notifier).state = PeriodeLaporan.bulan;
    ref.read(jangkarLaporanProvider.notifier).state = DateTime.now();
    ref.read(rentangKustomProvider.notifier).state = null;
  }

  void _lihatBulan(WidgetRef ref, DateTime d) {
    ref.read(jangkarLaporanProvider.notifier).state = DateTime(
      d.year,
      d.month,
      1,
    );
    ref.read(periodeLaporanProvider.notifier).state = PeriodeLaporan.bulan;
  }

  void _geser(WidgetRef ref, PeriodeLaporan p, int delta) {
    final a = ref.read(jangkarLaporanProvider);
    ref.read(jangkarLaporanProvider.notifier).state = switch (p) {
      PeriodeLaporan.minggu => a.add(Duration(days: 7 * delta)),
      PeriodeLaporan.bulan => DateTime(a.year, a.month + delta, 1),
      PeriodeLaporan.tahun => DateTime(a.year + delta, 1, 1),
      PeriodeLaporan.kustom => a,
    };
  }

  Future<void> _pilihKustom(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final hasil = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: ref.read(rentangKustomProvider),
    );
    if (hasil == null) return;
    ref.read(rentangKustomProvider.notifier).state = hasil;
    ref.read(periodeLaporanProvider.notifier).state = PeriodeLaporan.kustom;
  }

  Future<void> _pilihPeriode(
    BuildContext context,
    WidgetRef ref,
    PeriodeLaporan p,
  ) async {
    final a = ref.read(jangkarLaporanProvider);
    final now = DateTime.now();
    DateTime? hasil;

    switch (p) {
      case PeriodeLaporan.minggu:
        hasil = await showDatePicker(
          context: context,
          initialDate: a.isAfter(now) ? now : a,
          firstDate: DateTime(now.year - 5),
          lastDate: now,
          helpText: 'Pilih tanggal di minggu yang diinginkan',
        );
      case PeriodeLaporan.bulan:
      case PeriodeLaporan.tahun:
        hasil = await showAppSheet<DateTime>(
          context,
          (_) => _PilihPeriodeSheet(tahun: p == PeriodeLaporan.tahun, awal: a),
        );
      case PeriodeLaporan.kustom:
        await _pilihKustom(context, ref);
    }

    if (hasil != null) {
      ref.read(jangkarLaporanProvider.notifier).state = hasil;
    }
  }

  void _bukaKategori(
    BuildContext context,
    String kategori,
    double total,
    List<TransactionModel> items,
  ) {
    showAppSheet(
      context,
      (_) => _KategoriSheet(kategori: kategori, total: total, items: items),
    );
  }

  String _labelRentang(PeriodeLaporan p, RentangLaporan r) {
    final akhir = r.akhir.subtract(const Duration(days: 1));
    switch (p) {
      case PeriodeLaporan.bulan:
        return DateFormat('MMMM yyyy', 'id_ID').format(r.mulai);
      case PeriodeLaporan.tahun:
        return DateFormat('yyyy', 'id_ID').format(r.mulai);
      case PeriodeLaporan.minggu:
      case PeriodeLaporan.kustom:
        final a = DateFormat('d MMM', 'id_ID').format(r.mulai);
        final b = DateFormat('d MMM yyyy', 'id_ID').format(akhir);
        return '$a – $b';
    }
  }

  String _ringkas(double v) {
    if (v >= 1000000) {
      return 'Rp ${(v / 1000000).toStringAsFixed(1).replaceAll('.', ',')}jt';
    }
    if (v >= 1000) return 'Rp ${(v / 1000).round()}rb';
    return formatRupiah(v);
  }

  /// Indeks batang yang berisi hari ini, atau -1 kalau periode bukan yang berjalan.
  int _indeksBerjalan(RentangLaporan r, int jumlah) {
    final now = DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    if (hariIni.isBefore(r.mulai) || !hariIni.isBefore(r.akhir)) return -1;

    final hari = r.jumlahHari;
    final int i;
    if (hari <= 7) {
      i = hariIni.difference(r.mulai).inDays;
    } else if (hari <= 62) {
      i = hariIni.difference(r.mulai).inDays ~/ 7;
    } else {
      i =
          (hariIni.year * 12 + hariIni.month) -
          (r.mulai.year * 12 + r.mulai.month);
    }
    return (i >= 0 && i < jumlah) ? i : -1;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periode = ref.watch(periodeLaporanProvider);
    final jangkar = ref.watch(jangkarLaporanProvider);
    final rentang = ref.watch(rentangLaporanProvider);
    final ringkasan = ref.watch(ringkasanLaporanProvider);
    final sebelumnya = ref.watch(pengeluaranSebelumnyaProvider);
    final perKategori = ref.watch(pengeluaranPerKategoriLaporanProvider);
    final arusKas = ref.watch(arusKasLaporanProvider);
    final transaksi = ref.watch(transaksiLaporanProvider);
    final terakhir = ref.watch(transaksiTerakhirProvider);

    final total = ringkasan.pengeluaran;
    final bisaMaju = !rentang.akhir.isAfter(DateTime.now());

    // rata-rata per hari: hanya hari yang sudah berjalan
    final now = DateTime.now();
    final batas = DateTime(now.year, now.month, now.day + 1);
    final akhirEfektif = rentang.akhir.isBefore(batas) ? rentang.akhir : batas;
    final hariBerjalan = akhirEfektif.difference(rentang.mulai).inDays;
    final rata = total / (hariBerjalan < 1 ? 1 : hariBerjalan);

    final items = <Widget>[
      _buildFilter(context, ref, periode),
      const SizedBox(height: 6),
      _buildNavigator(
        context,
        ref,
        periode,
        _labelRentang(periode, rentang),
        bisaMaju,
      ),
      const SizedBox(height: 8),
      _buildTotalCard(
        context,
        total,
        ringkasan.pemasukan,
        sebelumnya,
        rentang.labelBanding,
      ),
      const SizedBox(height: 14),
      if (transaksi.isEmpty)
        _buildKosong(context, ref, terakhir)
      else ...[
        _buildArusKasCard(
          context,
          arusKas,
          _indeksBerjalan(rentang, arusKas.length),
        ),
        const SizedBox(height: 14),
        _buildInfoRow(context, perKategori, total, transaksi.length, rata),
        const SizedBox(height: 20),
        _grupJudul(context, 'Rincian Kategori'),
        if (perKategori.isEmpty)
          Text(
            'Belum ada pengeluaran pada periode ini.',
            style: AppTextStyles.caption,
          )
        else
          ...perKategori.map(
            (e) => _buildKategoriCard(context, e, total, transaksi),
          ),
      ],
    ];

    return ColoredBox(
      color: context.pal.background,
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, ref, !_isDefault(periode, jangkar)),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: items
                        .animate(interval: 45.ms)
                        .fadeIn(duration: 320.ms)
                        .slideY(
                          begin: .08,
                          end: 0,
                          duration: 380.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child:
                      PrimaryButton(
                            text: 'Ekspor Laporan PDF',
                            leading: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ekspor PDF segera hadir.'),
                                ),
                              );
                            },
                          )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 350.ms)
                          .slideY(
                            begin: .6,
                            end: 0,
                            delay: 400.ms,
                            duration: 450.ms,
                            curve: Curves.easeOutCubic,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _grupJudul(BuildContext context, String judul) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(judul, style: AppTextStyles.title.copyWith(fontSize: 18)),
        ],
      ),
    );
  }

  // ---------- HEADER ----------
  Widget _buildHeader(BuildContext context, WidgetRef ref, bool tampilReset) {
    final pal = context.pal;
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
                      color: pal.card,
                      border: Border.all(color: pal.outline, width: 0.5),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Laporan',
                  style: AppTextStyles.title.copyWith(fontSize: 20),
                ),
              ),
              if (tampilReset)
                PressableScale(
                      scale: .92,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _reset(ref);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: pal.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: pal.outline, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.refresh, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Reset',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .scale(
                      begin: const Offset(.8, .8),
                      duration: 250.ms,
                      curve: Curves.easeOutBack,
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

  // ---------- SEGMENTED CONTROL PERIODE ----------
  Widget _buildFilter(
    BuildContext context,
    WidgetRef ref,
    PeriodeLaporan aktif,
  ) {
    final pal = context.pal;
    const pilihan = [
      (PeriodeLaporan.minggu, 'Mingguan'),
      (PeriodeLaporan.bulan, 'Bulanan'),
      (PeriodeLaporan.tahun, 'Tahunan'),
      (PeriodeLaporan.kustom, 'Kustom'),
    ];
    final idx = pilihan.indexWhere((p) => p.$1 == aktif);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pal.outline, width: 0.5),
      ),
      child: Stack(
        children: [
          // Pill amber yang meluncur ke periode aktif.
          Positioned.fill(
            child: AnimatedAlign(
              duration: 280.ms,
              curve: Curves.easeOutCubic,
              alignment: Alignment(-1 + 2 * idx / (pilihan.length - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / pilihan.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: pilihan.map((p) {
              final selected = aktif == p.$1;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (p.$1 == PeriodeLaporan.kustom) {
                      _pilihKustom(context, ref);
                    } else {
                      ref.read(periodeLaporanProvider.notifier).state = p.$1;
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: 200.ms,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? const Color(0xFF2B1B10)
                            : pal.textSecondary,
                      ),
                      child: Text(p.$2),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------- NAVIGATOR ◀ label ▶ ----------
  Widget _buildNavigator(
    BuildContext context,
    WidgetRef ref,
    PeriodeLaporan p,
    String label,
    bool bisaMaju,
  ) {
    final pal = context.pal;
    final kustom = p == PeriodeLaporan.kustom;

    Widget panah(IconData icon, VoidCallback? onTap) => PressableScale(
      scale: .88,
      enabled: onTap != null,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap();
              },
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pal.card,
            border: Border.all(color: pal.outline, width: 0.5),
          ),
          child: Icon(
            icon,
            size: 20,
            color: onTap == null
                ? pal.textSecondary.withValues(alpha: 0.4)
                : null,
          ),
        ),
      ),
    );

    return Row(
      children: [
        panah(
          Icons.chevron_left_rounded,
          kustom ? null : () => _geser(ref, p, -1),
        ),
        Expanded(
          child: InkWell(
            onTap: () => _pilihPeriode(context, ref, p),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: 220.ms,
                      transitionBuilder: (c, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, .3),
                            end: Offset.zero,
                          ).animate(a),
                          child: c,
                        ),
                      ),
                      child: Text(
                        label,
                        key: ValueKey(label),
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),
        panah(
          Icons.chevron_right_rounded,
          (kustom || !bisaMaju) ? null : () => _geser(ref, p, 1),
        ),
      ],
    );
  }

  // ---------- KARTU KOSONG ----------
  Widget _buildKosong(BuildContext context, WidgetRef ref, DateTime? terakhir) {
    final pal = context.pal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pal.outline, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pal.primaryLight,
                  border: Border.all(color: pal.outline, width: 0.5),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 38,
                  color: pal.primaryDark,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: 0,
                end: -8,
                duration: 1400.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 14),
          Text(
            'Belum ada transaksi di periode ini',
            style: AppTextStyles.title.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            terakhir == null
                ? 'Catat transaksi pertamamu, laporan akan terisi otomatis.'
                : 'Data terakhirmu ada di ${DateFormat('MMMM yyyy', 'id_ID').format(terakhir)}.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          if (terakhir != null) ...[
            const SizedBox(height: 14),
            PressableScale(
              scale: .95,
              child: OutlinedButton(
                onPressed: () => _lihatBulan(ref, terakhir),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: pal.outline, width: 0.5),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Lihat ${DateFormat('MMMM yyyy', 'id_ID').format(terakhir)}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------- KARTU TOTAL (hero amber) ----------
  Widget _buildTotalCard(
    BuildContext context,
    double total,
    double pemasukan,
    double sebelumnya,
    String labelBanding,
  ) {
    const tinta = Color(0xFF2B1B10);
    final pal = context.pal;

    String? teks;
    bool naik = false;
    bool netral = false;

    if (total > 0) {
      if (sebelumnya > 0) {
        final persen = (total - sebelumnya) / sebelumnya * 100;
        naik = persen >= 0;
        teks =
            '${naik ? 'Naik' : 'Turun'} ${persen.abs().round()}% dari $labelBanding';
      } else {
        teks = 'Belum ada data $labelBanding untuk dibandingkan';
        netral = true;
      }
    }
    final warnaChip = netral
        ? const Color(0xFF6B5B4B)
        : (naik ? AppColors.error : AppColors.success);

    final selisih = pemasukan - total;
    final teksSelisih =
        '${selisih < 0 ? '-' : '+'}${formatRupiah(selisih.abs())}';

    Widget kotak(String label, String nilai) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: tinta.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              nilai,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w800,
                color: tinta,
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color.lerp(AppColors.primary, Colors.white, 0.3)!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pal.outline, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Pengeluaran',
            style: AppTextStyles.caption.copyWith(
              color: tinta.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: total),
            duration: 800.ms,
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text(
              formatRupiah(v),
              style: AppTextStyles.title.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: tinta,
              ),
            ),
          ),
          if (teks != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    netral
                        ? Icons.info_outline
                        : (naik ? Icons.trending_up : Icons.trending_down),
                    size: 14,
                    color: warnaChip,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      teks,
                      style: AppTextStyles.caption.copyWith(
                        color: warnaChip,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              kotak('Pemasukan', formatRupiah(pemasukan)),
              const SizedBox(width: 10),
              kotak('Selisih', teksSelisih),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- ARUS KAS (grafik) ----------
  Widget _buildArusKasCard(
    BuildContext context,
    List<TitikArusKas> data,
    int berjalan,
  ) {
    final pal = context.pal;
    final semuaNol = data.every((d) => d.masuk == 0 && d.keluar == 0);
    final tertinggi = data.fold<double>(
      0,
      (m, d) => [m, d.masuk, d.keluar].reduce((a, b) => a > b ? a : b),
    );
    final lebar = data.length <= 7
        ? 10.0
        : data.length <= 12
        ? 8.0
        : 5.0;

    Widget legenda(Color c, String t) => Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(t, style: AppTextStyles.caption),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pal.outline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Arus Kas',
                  style: AppTextStyles.title.copyWith(fontSize: 16),
                ),
              ),
              if (!semuaNol)
                Text('Sentuh batang', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: semuaNol
                ? Center(
                    child: Text(
                      'Belum ada transaksi pada periode ini.',
                      style: AppTextStyles.caption,
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: tertinggi * 1.2,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final d = data[group.x];
                            return BarTooltipItem(
                              '${d.label}\n'
                              'Keluar ${_ringkas(d.keluar)}\n'
                              'Masuk ${_ringkas(d.masuk)}',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (v, meta) {
                              final i = v.toInt();
                              if (i < 0 || i >= data.length) {
                                return const SizedBox.shrink();
                              }
                              final sekarang = i == berjalan;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  data[i].label,
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: sekarang
                                        ? FontWeight.w800
                                        : FontWeight.w400,
                                    color: sekarang ? pal.primaryDark : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(data.length, (i) {
                        // Periode berjalan pekat, lainnya sedikit pudar
                        final pudar = berjalan >= 0 && i != berjalan;
                        final a = pudar ? 0.55 : 1.0;
                        return BarChartGroupData(
                          x: i,
                          barsSpace: 3,
                          barRods: [
                            BarChartRodData(
                              toY: data[i].keluar,
                              color: AppColors.primary.withValues(alpha: a),
                              width: lebar,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            BarChartRodData(
                              toY: data[i].masuk,
                              color: _warnaPemasukan.withValues(alpha: a),
                              width: lebar,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              legenda(AppColors.primary, 'Pengeluaran'),
              const SizedBox(width: 18),
              legenda(_warnaPemasukan, 'Pemasukan'),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- KARTU INFO ----------
  Widget _buildInfoRow(
    BuildContext context,
    List<MapEntry<String, double>> perKategori,
    double total,
    int jumlahTransaksi,
    double rata,
  ) {
    final pal = context.pal;
    final teratas = perKategori.isEmpty ? null : perKategori.first;
    final persenTeratas = (teratas == null || total <= 0)
        ? 0
        : (teratas.value / total * 100).round();
    final warnaTeratas = teratas == null
        ? pal.primaryDark
        : categoryColor(teratas.key);

    BoxDecoration dekor() => BoxDecoration(
      color: pal.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: pal.outline, width: 0.5),
    );

    Widget kecil(IconData icon, String label, String nilai) => Container(
      padding: const EdgeInsets.all(12),
      decoration: dekor(),
      child: Row(
        children: [
          Icon(icon, size: 20, color: pal.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(
                  nilai,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: dekor(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    teratas == null
                        ? Icons.pie_chart_outline
                        : categoryIcon(teratas.key),
                    color: warnaTeratas,
                  ),
                  const SizedBox(height: 8),
                  Text('Kategori Terbesar', style: AppTextStyles.caption),
                  Text(
                    teratas?.key ?? '-',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$persenTeratas%',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 20,
                      color: warnaTeratas,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: kecil(
                    Icons.receipt_long_outlined,
                    'Transaksi',
                    '$jumlahTransaksi Kali',
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: kecil(
                    Icons.calendar_view_day_outlined,
                    'Rata-rata/hari',
                    _ringkas(rata),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- RINCIAN KATEGORI (bisa diketuk) ----------
  Widget _buildKategoriCard(
    BuildContext context,
    MapEntry<String, double> e,
    double total,
    List<TransactionModel> semuaTransaksi,
  ) {
    final pal = context.pal;
    final persen = total <= 0 ? 0.0 : (e.value / total).clamp(0.0, 1.0);
    final warna = categoryColor(e.key);
    final items =
        semuaTransaksi
            .where((t) => t.category == e.key && t.amount < 0)
            .toList()
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        scale: .98,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: pal.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: pal.outline, width: 0.5),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _bukaKategori(context, e.key, e.value, items);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: warna.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          categoryIcon(e.key),
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
                              e.key,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${items.length} transaksi',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatRupiah(e.value),
                            style: AppTextStyles.title.copyWith(fontSize: 15),
                          ),
                          Text(
                            '${(persen * 100).round()}%',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: warna,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: pal.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: persen),
                    duration: 900.ms,
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 8,
                        backgroundColor: pal.border,
                        color: warna,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// ================================================================
// SHEET RINCIAN TRANSAKSI PER KATEGORI
// ================================================================

class _KategoriSheet extends StatelessWidget {
  final String kategori;
  final double total;
  final List<TransactionModel> items;

  const _KategoriSheet({
    required this.kategori,
    required this.total,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final warna = categoryColor(kategori);

    return SheetFrame(
      title: kategori,
      subtitle: '${items.length} transaksi • ${formatRupiah(total)}',
      icon: categoryIcon(kategori),
      children: [
        if (items.isEmpty)
          Text('Tidak ada transaksi.', style: AppTextStyles.caption)
        else
          ...items
              .take(20)
              .map(
                (t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: warna.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryIcon(kategori),
                          size: 18,
                          color: warna,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'd MMM yyyy',
                                'id_ID',
                              ).format(t.transactionDate),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatRupiah(t.amount.abs()),
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        if (items.length > 20)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'dan ${items.length - 20} transaksi lainnya',
              style: AppTextStyles.caption,
            ),
          ),
      ],
    );
  }
}

// ================================================================
// SHEET PILIH BULAN / TAHUN
// ================================================================

class _PilihPeriodeSheet extends StatefulWidget {
  final bool tahun;
  final DateTime awal;

  const _PilihPeriodeSheet({required this.tahun, required this.awal});

  @override
  State<_PilihPeriodeSheet> createState() => _PilihPeriodeSheetState();
}

class _PilihPeriodeSheetState extends State<_PilihPeriodeSheet> {
  late int _tahun = widget.awal.year;

  Widget _chip(String label, bool selected, bool aktif, VoidCallback onTap) {
    final pal = context.pal;
    return PressableScale(
      scale: .94,
      enabled: aktif,
      child: GestureDetector(
        onTap: aktif
            ? () {
                HapticFeedback.selectionClick();
                onTap();
              }
            : null,
        child: AnimatedContainer(
          duration: 180.ms,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : pal.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : pal.outline,
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: selected
                  ? const Color(0xFF2B1B10)
                  : (aktif ? null : pal.textSecondary.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    if (widget.tahun) {
      final daftar = List.generate(6, (i) => now.year - 5 + i);
      return SheetFrame(
        title: 'Pilih Tahun',
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: daftar
                .map(
                  (y) => _chip(
                    '$y',
                    y == widget.awal.year,
                    true,
                    () => Navigator.pop(context, DateTime(y, 1, 1)),
                  ),
                )
                .toList(),
          ),
        ],
      );
    }

    return SheetFrame(
      title: 'Pilih Bulan',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _tahun--),
            ),
            Text('$_tahun', style: AppTextStyles.title.copyWith(fontSize: 18)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _tahun >= now.year
                  ? null
                  : () => setState(() => _tahun++),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(12, (i) {
            final m = i + 1;
            final aktif = !DateTime(_tahun, m).isAfter(now);
            final selected =
                _tahun == widget.awal.year && m == widget.awal.month;
            return _chip(
              DateFormat('MMM', 'id_ID').format(DateTime(2000, m)),
              selected,
              aktif,
              () => Navigator.pop(context, DateTime(_tahun, m, 1)),
            );
          }),
        ),
      ],
    );
  }
}
