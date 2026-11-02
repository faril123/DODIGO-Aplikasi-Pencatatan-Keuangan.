// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/models/transaction_model.dart';
import '../../shared/widgets/animated_count.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/pressable_scale.dart';
import '../../shared/widgets/transaction_detail_sheet.dart';
import '../../shared/widgets/transaction_tile.dart';
import '../../shared/widgets/header_line.dart';
import '../notification/notification_prompt.dart';
import 'transaction_provider.dart';

enum _Filter { semua, pemasukan, pengeluaran }

enum _Sort { terbaru, terlama, nominalTerbesar, nominalTerkecil }

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final _searchController = TextEditingController();
  _Filter _filter = _Filter.semua;
  _Sort _sort = _Sort.terbaru;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Logika data
  // ---------------------------------------------------------------------------

  String _labelTanggal(DateTime tanggal) {
    final now = DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    final target = DateTime(tanggal.year, tanggal.month, tanggal.day);
    final selisih = hariIni.difference(target).inDays;

    if (selisih == 0) return 'Hari Ini';
    if (selisih == 1) return 'Kemarin';
    return DateFormat('d MMMM yyyy', 'id_ID').format(tanggal);
  }

  Map<String, List<TransactionModel>> _kelompokkanPerTanggal(
    List<TransactionModel> transaksi,
  ) {
    final Map<String, List<TransactionModel>> hasil = {};
    for (final t in transaksi) {
      final label = _labelTanggal(t.transactionDate);
      hasil.putIfAbsent(label, () => []).add(t);
    }
    return hasil;
  }

  List<TransactionModel> _terapkanFilter(List<TransactionModel> semua) {
    var hasil = semua;

    if (_filter == _Filter.pemasukan) {
      hasil = hasil.where((t) => t.amount > 0).toList();
    } else if (_filter == _Filter.pengeluaran) {
      hasil = hasil.where((t) => t.amount < 0).toList();
    }

    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      hasil = hasil
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.category.toLowerCase().contains(q),
          )
          .toList();
    }

    hasil = [...hasil];
    switch (_sort) {
      case _Sort.terbaru:
        hasil.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
        break;
      case _Sort.terlama:
        hasil.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
        break;
      case _Sort.nominalTerbesar:
        hasil.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
        break;
      case _Sort.nominalTerkecil:
        hasil.sort((a, b) => a.amount.abs().compareTo(b.amount.abs()));
        break;
    }

    return hasil;
  }

  void _resetFilter() {
    _searchController.clear();
    setState(() {
      _query = '';
      _filter = _Filter.semua;
    });
  }

  Future<bool> _konfirmasiHapus(BuildContext context) async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text('Transaksi ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return hasil ?? false;
  }

  // ---------------------------------------------------------------------------
  // Sort sheet
  // ---------------------------------------------------------------------------

  void _bukaMenuSort() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Urutkan', style: AppTextStyles.title),
              ),
            ),
            _buildSortOption('Terbaru', Icons.schedule, _Sort.terbaru),
            _buildSortOption('Terlama', Icons.history, _Sort.terlama),
            _buildSortOption(
              'Nominal Terbesar',
              Icons.trending_up_rounded,
              _Sort.nominalTerbesar,
            ),
            _buildSortOption(
              'Nominal Terkecil',
              Icons.trending_down_rounded,
              _Sort.nominalTerkecil,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, IconData icon, _Sort value) {
    final selected = _sort == value;
    return ListTile(
      leading: Icon(icon),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: selected,
      selectedColor: context.pal.primaryDark,
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _sort = value);
        Navigator.pop(context);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final transaksiAsync = ref.watch(transactionsProvider);

    return ColoredBox(
      color: context.pal.background,
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Riwayat Transaksi'),
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
          body: Column(
            children: [
              _buildSearchRow(),
              _buildFilterRow(),
              const SizedBox(height: 8),
              Expanded(
                child: transaksiAsync.when(
                  loading: _buildSkeleton,
                  error: (err, _) =>
                      Center(child: Text('Gagal memuat data: $err')),
                  data: (semuaTransaksi) {
                    final transaksi = _terapkanFilter(semuaTransaksi);

                    if (transaksi.isEmpty) {
                      return _buildEmpty(semuaTransaksi.isEmpty);
                    }

                    final totalPemasukan = transaksi
                        .where((t) => t.amount > 0)
                        .fold(0.0, (sum, t) => sum + t.amount);
                    final totalPengeluaran = transaksi
                        .where((t) => t.amount < 0)
                        .fold(0.0, (sum, t) => sum + t.amount.abs());

                    final grup = _kelompokkanPerTanggal(transaksi);
                    var index = 0;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        _buildRingkasan(totalPemasukan, totalPengeluaran),
                        const SizedBox(height: 4),
                        for (final entry in grup.entries) ...[
                          _buildGroupHeader(entry.key, entry.value.length),
                          for (final t in entry.value) _buildTile(t, index++),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pencarian & filter
  // ---------------------------------------------------------------------------

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Cari transaksi...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: context.pal.field,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: _fieldBorder(context.pal.border),
                enabledBorder: _fieldBorder(context.pal.border),
                focusedBorder: _fieldBorder(AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: context.pal.field,
                  border: Border.all(color: context.pal.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: _bukaMenuSort,
                ),
              ),
              if (_sort != _Sort.terbaru)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -.2, end: 0);
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('Semua', _Filter.semua),
          const SizedBox(width: 8),
          _buildFilterChip('Pemasukan', _Filter.pemasukan),
          const SizedBox(width: 8),
          _buildFilterChip('Pengeluaran', _Filter.pengeluaran),
        ],
      ),
    ).animate().fadeIn(delay: 80.ms, duration: 350.ms);
  }

  Widget _buildFilterChip(String label, _Filter value) {
    final selected = _filter == value;
    return PressableScale(
      scale: .94,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filter = value);
        },
        child: AnimatedContainer(
          duration: 220.ms,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : context.pal.border,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: 220.ms,
            style: AppTextStyles.caption.copyWith(
              color: selected
                  ? const Color(0xFF2B1B10)
                  : context.pal.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Ringkasan
  // ---------------------------------------------------------------------------

  Widget _buildRingkasan(double pemasukan, double pengeluaran) {
    final total = pemasukan + pengeluaran;
    final rasio = total == 0 ? 0.5 : pemasukan / total;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildRingkasanCard(
                'Pemasukan',
                pemasukan,
                context.pal.success,
                Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRingkasanCard(
                'Pengeluaran',
                pengeluaran,
                context.pal.error,
                Icons.arrow_upward_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: .5, end: rasio),
          duration: 700.ms,
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              color: context.pal.error.withValues(alpha: .35),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: v,
                child: Container(color: context.pal.success),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: .1, end: 0);
  }

  Widget _buildRingkasanCard(
    String label,
    double total,
    Color warna,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warna.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: warna, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedCount(
                    value: total,
                    format: (v) => formatRupiah(v),
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: warna,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Daftar
  // ---------------------------------------------------------------------------

  Widget _buildGroupHeader(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
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
          Text(label, style: AppTextStyles.title),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: context.pal.border)),
          const SizedBox(width: 10),
          Text('$count transaksi', style: AppTextStyles.caption),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTile(TransactionModel t, int i) {
    final delay = ((i > 8 ? 8 : i) * 40).ms;

    return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Dismissible(
            key: ValueKey(t.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              if (await _konfirmasiHapus(context) != true) {
                return false;
              }
              try {
                await ref
                    .read(transactionRepositoryProvider)
                    .deleteTransaction(t.id);
                return true;
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus transaksi: $e')),
                  );
                }
                return false;
              }
            },
            onDismissed: (_) async {
              ref.invalidate(transactionsProvider);
              await jadwalkanUlangSemua(ref);
            },
            child: PressableScale(
              scale: .98,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => showTransactionDetail(context, t),
                child: TransactionTile(transaction: t),
              ),
            ),
          ),
        )
        // key di elemen paling luar supaya Dismissible tidak tertukar state.
        .animate(key: ValueKey('tile-${t.id}'))
        .fadeIn(delay: delay, duration: 300.ms)
        .slideY(
          begin: .15,
          end: 0,
          delay: delay,
          duration: 380.ms,
          curve: Curves.easeOutCubic,
        );
  }

  // ---------------------------------------------------------------------------
  // Empty state & skeleton
  // ---------------------------------------------------------------------------

  Widget _buildEmpty(bool belumAdaTransaksi) {
    final filterAktif = _query.trim().isNotEmpty || _filter != _Filter.semua;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: context.pal.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.pal.outline, width: .8),
                  ),
                  child: Icon(
                    belumAdaTransaksi
                        ? Icons.receipt_long_outlined
                        : Icons.search_off_rounded,
                    size: 44,
                    color: context.pal.primaryDark,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                  begin: -6,
                  end: 6,
                  duration: 1800.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 16),
            Text(
              belumAdaTransaksi
                  ? 'Belum ada transaksi'
                  : 'Tidak ada yang cocok',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 4),
            Text(
              belumAdaTransaksi
                  ? 'Transaksi yang kamu catat akan muncul di sini.'
                  : 'Coba ubah kata kunci atau filter.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            if (!belumAdaTransaksi && filterAktif) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _resetFilter,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset filter'),
              ),
            ],
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildSkeleton() {
    Widget box(double h, {double r = 16}) => Container(
      height: h,
      decoration: BoxDecoration(
        color: context.pal.border,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Row(
              children: [
                Expanded(child: box(60, r: 14)),
                const SizedBox(width: 8),
                Expanded(child: box(60, r: 14)),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(width: 110, child: box(16)),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < 5; i++) ...[
              box(64, r: 20),
              const SizedBox(height: 8),
            ],
          ],
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          color: context.pal.card.withValues(alpha: .6),
        );
  }
}
