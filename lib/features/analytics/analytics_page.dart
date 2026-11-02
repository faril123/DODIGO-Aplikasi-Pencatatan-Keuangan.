import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/category_style.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/animated_count.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/header_line.dart';
import '../../shared/widgets/pressable_scale.dart';
import 'analytics_provider.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  // static const, jadi tidak bisa memakai context.pal.
  static const _warnaDistribusi = [
    accentBrown,
    accentBlue,
    AppColors.textSecondary,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periode = ref.watch(periodeAnalitikProvider);
    final offset = ref.watch(offsetPeriodeProvider);
    final total = ref.watch(totalPengeluaranPeriodeProvider);
    final tren = ref.watch(trenPeriodeProvider);
    final distribusi = ref.watch(distribusiDonutProvider);
    final kategoriTerbanyak = ref.watch(kategoriTerbanyakProvider);
    final insight = ref.watch(insightAnalitikProvider);

    // Berubah tiap periode/offset berganti -> animasi grafik diputar ulang.
    final animKey = '${periode.name}-$offset';

    final labelPengeluaran = switch (periode) {
      Periode.minggu => 'Pengeluaran minggu ini',
      Periode.bulan => 'Pengeluaran bulan ini',
      Periode.tahun => 'Pengeluaran tahun ini',
    };

    return ColoredBox(
      color: context.pal.background,
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Analitik'),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(12),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: HeaderLine(),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children:
                <Widget>[
                      _buildPeriodeSelector(context, ref, periode),
                      const SizedBox(height: 14),
                      _buildNavigasiPeriode(context, ref),
                      const SizedBox(height: 20),
                      _buildTotalCard(context, labelPengeluaran, total),
                      const SizedBox(height: 16),
                      _buildTrenCard(context, tren, animKey),
                      const SizedBox(height: 16),
                      _buildDistribusiCard(context, distribusi, animKey),
                      const SizedBox(height: 16),
                      _buildKategoriTerbanyakCard(context, kategoriTerbanyak),
                      const SizedBox(height: 16),
                      _buildInsightCard(context, periode, insight),
                      const SizedBox(height: 80),
                    ]
                    .animate(interval: 70.ms)
                    .fadeIn(duration: 380.ms)
                    .slideY(
                      begin: .1,
                      end: 0,
                      duration: 450.ms,
                      curve: Curves.easeOutCubic,
                    ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPER
  // ============================================================

  Widget _card(
    BuildContext context, {
    required Widget child,
    Color? color,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? context.pal.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? context.pal.outline,
          width: 0.5,
        ),
      ),
      child: child,
    );
  }

  Widget _cardTitle(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(text, style: AppTextStyles.title.copyWith(fontSize: 15)),
      ],
    );
  }

  // ============================================================
  // KARTU TOTAL
  // ============================================================

  Widget _buildTotalCard(BuildContext context, String label, double total) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.pal.outline, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              AnimatedCount(
                value: total,
                format: (v) => formatRupiah(v),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVIGASI PERIODE
  // ============================================================

  Widget _buildNavigasiPeriode(BuildContext context, WidgetRef ref) {
    final offset = ref.watch(offsetPeriodeProvider);
    final maxOffset = ref.watch(maxOffsetPeriodeProvider);
    final label = ref.watch(labelPeriodeAktifProvider);

    final bisaMundur = offset < maxOffset;
    final bisaMaju = offset > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPeriodArrowButton(
          context: context,
          icon: Icons.chevron_left_rounded,
          enabled: bisaMundur,
          onTap: !bisaMundur
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  ref.read(offsetPeriodeProvider.notifier).state = offset + 1;
                },
        ),
        const SizedBox(width: 10),
        AnimatedSize(
          duration: 220.ms,
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: context.pal.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.pal.border, width: 0.9),
            ),
            child: AnimatedSwitcher(
              duration: 250.ms,
              child: Row(
                key: ValueKey(label),
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildPeriodArrowButton(
          context: context,
          icon: Icons.chevron_right_rounded,
          enabled: bisaMaju,
          onTap: !bisaMaju
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  ref.read(offsetPeriodeProvider.notifier).state = offset - 1;
                },
        ),
      ],
    );
  }

  Widget _buildPeriodArrowButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return PressableScale(
      enabled: enabled,
      scale: .9,
      child: AnimatedContainer(
        duration: 180.ms,
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: enabled
              ? context.pal.primaryLight
              : context.pal.primaryLight.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: context.pal.outline, width: 0.5),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          icon: Icon(
            icon,
            size: 23,
            color: enabled
                ? AppColors.primary
                : context.pal.textSecondary.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodeSelector(
    BuildContext context,
    WidgetRef ref,
    Periode aktif,
  ) {
    final items = [
      (Periode.minggu, 'Minggu'),
      (Periode.bulan, 'Bulan'),
      (Periode.tahun, 'Tahun'),
    ];
    final index = items.indexWhere((e) => e.$1 == aktif);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.pal.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.pal.outline, width: 0.5),
      ),
      child: Stack(
        children: [
          // Pill amber yang meluncur ke tab aktif.
          Positioned.fill(
            child: AnimatedAlign(
              duration: 280.ms,
              curve: Curves.easeOutCubic,
              alignment: Alignment(index - 1.0, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / 3,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: items.map((item) {
              final selected = aktif == item.$1;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (selected) return;
                    HapticFeedback.selectionClick();
                    ref.read(periodeAnalitikProvider.notifier).state = item.$1;
                    ref.read(offsetPeriodeProvider.notifier).state = 0;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: 180.ms,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? const Color(0xFF2B1B10)
                            : context.pal.textSecondary,
                      ),
                      child: Text(item.$2),
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

  // ============================================================
  // KARTU TREN
  // ============================================================

  Widget _buildTrenCard(
    BuildContext context,
    List<TitikTren> tren,
    String animKey,
  ) {
    final pal = context.pal;
    final maxY = tren.fold(0.0, (a, b) => a > b.nilai ? a : b.nilai);
    final chartMax = maxY <= 0 ? 10.0 : maxY * 1.3;
    final kosong = tren.every((t) => t.nilai == 0);

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(context, Icons.bar_chart_rounded, 'Tren'),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: kosong
                ? Center(
                    child: Text(
                      'Belum ada data.',
                      style: AppTextStyles.caption,
                    ),
                  )
                : TweenAnimationBuilder<double>(
                    key: ValueKey(animKey),
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: 700.ms,
                    curve: Curves.easeOutCubic,
                    builder: (context, f, _) => BarChart(
                      BarChartData(
                        maxY: chartMax,
                        alignment: BarChartAlignment.spaceAround,
                        groupsSpace: 8,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                formatRupiah(rod.toY),
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();

                                if (index < 0 || index >= tren.length) {
                                  return const SizedBox();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    tren[index].label,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 9,
                                      fontWeight: tren[index].hariIni
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: tren[index].hariIni
                                          ? accentBlue
                                          : pal.textSecondary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(tren.length, (index) {
                          final item = tren[index];

                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: item.nilai * f,
                                color: item.hariIni
                                    ? accentBlue
                                    : accentBrown.withValues(alpha: 0.55),
                                width: 10,
                                borderRadius: BorderRadius.circular(5),
                                // Track tipis di belakang batang.
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: chartMax,
                                  color: pal.border.withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU DISTRIBUSI
  // ============================================================

  Widget _buildDistribusiCard(
    BuildContext context,
    List<DistribusiSlice> distribusi,
    String animKey,
  ) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(context, Icons.donut_large_rounded, 'Distribusi'),
          const SizedBox(height: 16),
          if (distribusi.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada pengeluaran.',
                  style: AppTextStyles.caption,
                ),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(animKey),
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: 800.ms,
                    curve: Curves.easeOutCubic,
                    builder: (context, f, _) => PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 34,
                        startDegreeOffset: -90,
                        sections: List.generate(distribusi.length, (i) {
                          final slice = distribusi[i];
                          return PieChartSectionData(
                            value: slice.nominal,
                            color:
                                _warnaDistribusi[i % _warnaDistribusi.length],
                            radius: 26 * f,
                            showTitle: false,
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(distribusi.length, (i) {
                      final slice = distribusi[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color:
                                    _warnaDistribusi[i %
                                        _warnaDistribusi.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slice.nama,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    formatRupiah(slice.nominal),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${slice.persen.toStringAsFixed(0)}%',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU KATEGORI TERBANYAK
  // ============================================================

  Widget _kategoriRow(
    BuildContext context,
    KategoriRingkasan k,
    double maxNominal,
  ) {
    final warna = categoryColor(k.nama);
    final progress = maxNominal <= 0 ? 0.0 : k.nominal / maxNominal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(categoryIcon(k.nama), color: warna, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k.nama,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: 700.ms,
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: context.pal.border,
                      color: warna,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupiah(k.nominal),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${k.persen.toStringAsFixed(0)}%',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _bukaSemuaKategori(
    BuildContext context,
    List<KategoriRingkasan> kategori,
  ) {
    final maxNominal = kategori.isEmpty ? 0.0 : kategori.first.nominal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Semua Kategori', style: AppTextStyles.title),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: kategori
                    .map((k) => _kategoriRow(ctx, k, maxNominal))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKategoriTerbanyakCard(
    BuildContext context,
    List<KategoriRingkasan> kategori,
  ) {
    final maxNominal = kategori.isEmpty ? 0.0 : kategori.first.nominal;
    final tampil = kategori.take(3).toList();

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cardTitle(
                context,
                Icons.emoji_events_outlined,
                'Kategori Terbanyak',
              ),
              if (kategori.length > 3)
                PressableScale(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _bukaSemuaKategori(context, kategori);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: context.pal.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Lihat Semua',
                        style: AppTextStyles.caption.copyWith(
                          color: context.pal.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (tampil.isEmpty)
            Text('Belum ada pengeluaran.', style: AppTextStyles.caption)
          else
            ...tampil.map((k) => _kategoriRow(context, k, maxNominal)),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU INSIGHT
  // ============================================================

  Widget _buildInsightCard(
    BuildContext context,
    Periode periode,
    InsightAnalitik insight,
  ) {
    final labelPeriode = switch (periode) {
      Periode.minggu => 'Minggu',
      Periode.bulan => 'Bulan',
      Periode.tahun => 'Tahun',
    };
    final warna = insight.positif ? context.pal.success : context.pal.error;

    return _card(
      context,
      color: warna.withValues(alpha: 0.12),
      borderColor: warna.withValues(alpha: 0.25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: warna.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  insight.positif
                      ? Icons.emoji_events_outlined
                      : Icons.info_outline,
                  color: warna,
                  size: 22,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1,
                end: 1.08,
                duration: 1400.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insight $labelPeriode Ini',
                  style: AppTextStyles.title.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(insight.pesan, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
