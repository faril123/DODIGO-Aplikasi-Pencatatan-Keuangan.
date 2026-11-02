// ignore_for_file: deprecated_member_use

import 'package:didigo/shared/models/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_categories.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/rupiah_input_formatter.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/category_style.dart';

import '../../../shared/models/bill_model.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/header_line.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/filter_pills.dart';
import '../Target/target_form_widgets.dart' show QuickChip;
import '../../../shared/widgets/app_form_widgets.dart';

import '../../notification/notification_prompt.dart';
import '../../transaction/transaction_provider.dart';
import '../../wallet/wallet_provider.dart';
import 'tagihan_provider.dart';

final filterTagihanProvider = StateProvider<int>((ref) => 0);

class TagihanPage extends ConsumerWidget {
  const TagihanPage({super.key});

  // ============================================================
  // AKSI
  // ============================================================

  void _bukaFormTagihan(BuildContext context) {
    showAppSheet(context, (_) => const _BillFormSheet());
  }

  void _bukaEdit(BuildContext context, BillModel bill) {
    showAppSheet(context, (_) => _BillFormSheet(bill: bill));
  }

  void _bayar(BuildContext context, BillModel bill) {
    showAppSheet(context, (_) => _BayarSheet(bill: bill));
  }

  Future<void> _hapus(
    BuildContext context,
    WidgetRef ref,
    BillModel bill,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus "${bill.title}"?'),
        content: Text(
          bill.isRecurring
              ? 'Tagihan rutin ini tidak akan berlanjut ke bulan berikutnya.'
              : 'Tagihan ini akan dihapus.',
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
    if (ok != true) return;

    try {
      await ref.read(billsRepositoryProvider).deleteBill(bill.id);
      ref.invalidate(billsProvider);
      await jadwalkanUlangTagihan(ref);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus tagihan: $e')));
      }
    }
  }

  // ============================================================
  // HELPER
  // ============================================================

  ({String teks, Color warna, bool mendesak}) _statusTagihan(
    BuildContext context,
    BillModel b,
  ) {
    final now = DateTime.now();
    final d = b.dueDate;
    final sisa = DateTime(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;

    if (sisa < 0) {
      return (
        teks: 'Terlambat ${-sisa} hari',
        warna: AppColors.error,
        mendesak: true,
      );
    }
    if (sisa == 0) {
      return (teks: 'Hari ini', warna: AppColors.error, mendesak: true);
    }
    if (sisa <= 3) {
      return (teks: 'Segera', warna: AppColors.primaryDark, mendesak: true);
    }
    if (sisa <= 7) {
      return (teks: '$sisa hari lagi', warna: AppColors.error, mendesak: false);
    }
    return (
      teks: '$sisa hari lagi',
      warna: context.pal.textSecondary,
      mendesak: false,
    );
  }

  ({IconData icon, Color warna}) _gayaTagihan(BillModel b) {
    final t = '${b.title} ${b.category}'.toLowerCase();
    if (t.contains('listrik') || t.contains('pln')) {
      return (icon: Icons.bolt, warna: const Color(0xFFF5A623));
    }
    if (t.contains('internet') || t.contains('wifi')) {
      return (icon: Icons.language, warna: const Color(0xFF8D6E63));
    }
    if (t.contains('pdam') || t.startsWith('air')) {
      return (icon: Icons.water_drop, warna: const Color(0xFF29B6F6));
    }
    return (icon: categoryIcon(b.category), warna: categoryColor(b.category));
  }

  int _sisaHari(BillModel b) {
    final now = DateTime.now();
    final d = b.dueDate;
    return DateTime(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  List<Widget> _buildKelompok(
    BuildContext context,
    WidgetRef ref,
    List<BillModel> bills,
  ) {
    final terlambat = bills.where((b) => _sisaHari(b) < 0).toList();
    final mingguIni = bills
        .where((b) => _sisaHari(b) >= 0 && _sisaHari(b) <= 7)
        .toList();
    final nanti = bills.where((b) => _sisaHari(b) > 7).toList();

    List<Widget> grup(String judul, List<BillModel> list, {Color? warna}) {
      if (list.isEmpty) return [];
      return [
        _grupJudul(context, judul, list.length, warna: warna),
        ...list.map((b) => _buildBillCard(context, ref, b)),
        const SizedBox(height: 8),
      ];
    }

    return [
      ...grup('Terlambat', terlambat, warna: AppColors.error),
      ...grup('Minggu Ini', mingguIni),
      ...grup('Nanti', nanti),
    ];
  }

  Widget _grupJudul(BuildContext context, String judul, int n, {Color? warna}) {
    final pal = context.pal;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: warna ?? AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            judul,
            style: AppTextStyles.title.copyWith(fontSize: 18, color: warna),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: pal.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$n',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    final filter = ref.watch(filterTagihanProvider);

    return ColoredBox(
      color: context.pal.background,
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: FilterPills(
                    labels: const ['Belum Lunas', 'Lunas', 'Semua'],
                    selected: filter,
                    onChanged: (i) =>
                        ref.read(filterTagihanProvider.notifier).state = i,
                  ),
                ),
                Expanded(
                  child: billsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) =>
                        Center(child: Text('Gagal memuat data: $err')),
                    data: (bills) {
                      if (bills.isEmpty) {
                        return _buildEmpty(
                          context,
                          'Belum ada tagihan',
                          'Tekan "Tambah Tagihan" untuk mencatat tagihan pertamamu.',
                        );
                      }

                      final belumLunas = bills.where((b) => !b.isPaid).toList()
                        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
                      final sudahLunas = bills.where((b) => b.isPaid).toList();
                      final tampilBelum = filter == 1
                          ? <BillModel>[]
                          : belumLunas;
                      final tampilLunas = filter == 0
                          ? <BillModel>[]
                          : sudahLunas;

                      final now = DateTime.now();
                      final relevan = bills
                          .where(
                            (b) =>
                                (b.dueDate.year == now.year &&
                                    b.dueDate.month == now.month) ||
                                b.isOverdue,
                          )
                          .toList();
                      final total = relevan.fold<double>(
                        0,
                        (a, b) => a + b.amount,
                      );
                      final dibayar = relevan
                          .where((b) => b.isPaid)
                          .fold<double>(0, (a, b) => a + b.amount);
                      final nLunas = relevan.where((b) => b.isPaid).length;

                      final items = <Widget>[
                        _buildTotalCard(
                          context,
                          total,
                          dibayar,
                          relevan.length,
                          nLunas,
                        ),
                        const SizedBox(height: 20),
                        ..._buildKelompok(context, ref, tampilBelum),
                        if (tampilLunas.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _grupJudul(
                            context,
                            'Sudah Lunas',
                            tampilLunas.length,
                          ),
                          ...tampilLunas.map(
                            (b) => _buildBillCard(context, ref, b),
                          ),
                        ],
                        if (tampilBelum.isEmpty && tampilLunas.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: _buildEmpty(
                              context,
                              'Tidak ada tagihan',
                              'Coba ganti filter di atas.',
                            ),
                          ),
                      ];

                      // key = filter, jadi animasi masuk main lagi saat filter ganti.
                      return ListView(
                        key: ValueKey(filter),
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
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child:
                      PrimaryButton(
                            text: 'Tambah Tagihan',
                            leading: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => _bukaFormTagihan(context),
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

  Widget _buildHeader(BuildContext context) {
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
                  'Tagihan',
                  style: AppTextStyles.title.copyWith(fontSize: 20),
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

  Widget _buildEmpty(BuildContext context, String judul, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.pal.primaryLight,
                    border: Border.all(color: context.pal.outline, width: 0.5),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 38,
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
            const SizedBox(height: 14),
            Text(
              judul,
              style: AppTextStyles.title.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------- KARTU TOTAL ----------
  Widget _buildTotalCard(
    BuildContext context,
    double total,
    double dibayar,
    int jumlah,
    int lunas,
  ) {
    final pal = context.pal;
    final progress = total <= 0 ? 0.0 : (dibayar / total).clamp(0.0, 1.0);
    final sisa = (total - dibayar).clamp(0.0, double.infinity).toDouble();
    final semuaLunas = total > 0 && progress >= 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                  'Total Tagihan Bulan Ini',
                  style: AppTextStyles.caption,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: pal.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$lunas/$jumlah lunas',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: pal.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(end: total),
            duration: 900.ms,
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text(
              formatRupiah(v),
              style: AppTextStyles.title.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: 900.ms,
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: pal.border,
                color: semuaLunas ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statMini(
                  context,
                  'Dibayar',
                  formatRupiah(dibayar),
                  pal.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statMini(
                  context,
                  semuaLunas ? 'Semua lunas 🎉' : 'Sisa',
                  formatRupiah(sisa),
                  sisa > 0 ? pal.error : pal.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statMini(BuildContext context, String label, String nilai, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(
            nilai,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w800,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- KARTU TAGIHAN ----------
  Widget _buildBillCard(BuildContext context, WidgetRef ref, BillModel bill) {
    final pal = context.pal;
    final gaya = _gayaTagihan(bill);
    final status = _statusTagihan(context, bill);
    final lunas = bill.isPaid;
    final merah = !lunas && status.mendesak;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        scale: .98,
        enabled: !lunas,
        child: Opacity(
          opacity: lunas ? 0.65 : 1,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: pal.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: merah ? pal.error.withValues(alpha: 0.5) : pal.outline,
                width: merah ? 1 : 0.5,
              ),
            ),
            child: InkWell(
              onTap: lunas
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _bayar(context, bill);
                    },
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    if (merah) Container(width: 5, color: pal.error),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: (lunas ? pal.success : gaya.warna)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                lunas ? Icons.check_rounded : gaya.icon,
                                color: lunas ? pal.success : gaya.warna,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bill.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    formatRupiah(bill.amount),
                                    style: AppTextStyles.title.copyWith(
                                      fontSize: 18,
                                      decoration: lunas
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Jatuh tempo ${DateFormat('d MMM yyyy', 'id_ID').format(bill.dueDate)}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: merah
                                          ? pal.error
                                          : pal.textSecondary,
                                    ),
                                  ),
                                  if (bill.isRecurring)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.repeat_rounded,
                                          size: 12,
                                          color: pal.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            bill.recurringTotalMonths == null
                                                ? 'Rutin • bulan ke-${bill.recurringOccurrence}'
                                                : 'Rutin • bulan ke-${bill.recurringOccurrence} dari ${bill.recurringTotalMonths}',
                                            style: AppTextStyles.caption,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            _statusChip(
                              lunas ? 'Lunas' : status.teks,
                              lunas ? pal.success : status.warna,
                            ),
                            if (!lunas)
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.more_vert, size: 20),
                                onSelected: (v) {
                                  if (v == 'edit') _bukaEdit(context, bill);
                                  if (v == 'hapus') _hapus(context, ref, bill);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'hapus',
                                    child: Text('Hapus'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
}

// ================================================================
// FORM TAGIHAN (BARU & EDIT)
// ================================================================

class _BillFormSheet extends ConsumerStatefulWidget {
  final BillModel? bill; // null = tagihan baru, isi = mode edit

  const _BillFormSheet({this.bill});

  @override
  ConsumerState<_BillFormSheet> createState() => _BillFormSheetState();
}

class _BillFormSheetState extends ConsumerState<_BillFormSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _totalBulanController = TextEditingController(text: '3');

  String _kategori = 'Tagihan';
  DateTime _dueDate = DateTime.now();
  bool _recurring = false;
  bool _saving = false;
  bool _tanpaBatas = true;

  @override
  void initState() {
    super.initState();
    final b = widget.bill;
    if (b != null) {
      _titleController.text = b.title;
      _amountController.text = NumberFormat('#,##0', 'id_ID').format(b.amount);
      _kategori = b.category;
      _dueDate = b.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _totalBulanController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final hasil = await pilihTanggalApp(
      context,
      initial: _dueDate,
      first: DateTime.now().subtract(const Duration(days: 365)),
    );
    if (hasil != null) setState(() => _dueDate = hasil);
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
        const SnackBar(content: Text('Nama dan nominal tagihan wajib diisi.')),
      );
      return;
    }

    // ----- MODE EDIT -----
    if (widget.bill != null) {
      setState(() => _saving = true);
      try {
        final b = widget.bill!;
        await ref
            .read(billsRepositoryProvider)
            .updateBill(
              BillModel(
                id: b.id,
                title: title,
                category: _kategori,
                amount: amount,
                dueDate: _dueDate,
                isPaid: b.isPaid,
                isRecurring: b.isRecurring,
                recurringTotalMonths: b.recurringTotalMonths,
                recurringOccurrence: b.recurringOccurrence,
              ),
            );
        ref.invalidate(billsProvider);
        await jadwalkanUlangTagihan(ref);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }

    // ----- MODE BARU -----
    int? recurringTotalMonths;
    if (_recurring && !_tanpaBatas) {
      recurringTotalMonths = int.tryParse(_totalBulanController.text);
      if (recurringTotalMonths == null || recurringTotalMonths < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah bulan tidak valid.')),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      await ref
          .read(billsRepositoryProvider)
          .addBill(
            BillModel(
              id: '',
              title: title,
              category: _kategori,
              amount: amount,
              dueDate: _dueDate,
              isPaid: false,
              isRecurring: _recurring,
              recurringTotalMonths: recurringTotalMonths,
            ),
          );
      ref.invalidate(billsProvider);

      if (!mounted) return;
      await tawarkanNotif(context, ref, JenisReminder.tagihan);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan tagihan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeEdit = widget.bill != null;

    return SheetFrame(
      title: modeEdit ? 'Edit Tagihan' : 'Tagihan Baru',
      subtitle: 'Catat tagihan supaya tidak terlewat',
      icon: modeEdit ? Icons.edit_rounded : Icons.receipt_long_rounded,
      children: [
        TextField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          decoration: appInput(
            'Nama tagihan',
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [RupiahInputFormatter()],
          decoration: appInput(
            'Nominal',
            prefix: 'Rp ',
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(height: 14),
        _buildKategori(),
        const SizedBox(height: 14),
        DateField(
          label: 'Jatuh tempo',
          hint: 'Pilih tanggal',
          value: _dueDate,
          onTap: _pilihTanggal,
        ),
        const SizedBox(height: 12),
        _buildRutin(modeEdit),
        const SizedBox(height: 20),
        PrimaryButton(text: 'Simpan', loading: _saving, onPressed: _simpan),
      ],
    );
  }

  Widget _buildKategori() {
    final pal = context.pal;
    final daftar = AppCategories.expense;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: AppTextStyles.caption),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: daftar.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final k = daftar[i];
              final sel = k.label == _kategori;
              final warna = categoryColor(k.label);
              return PressableScale(
                scale: .94,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _kategori = k.label);
                  },
                  child: AnimatedContainer(
                    duration: 180.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? warna : warna.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? warna : pal.outline,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          k.icon,
                          size: 16,
                          color: sel ? Colors.white : warna,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          k.label,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : pal.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRutin(bool modeEdit) {
    if (modeEdit) return const SizedBox(width: double.infinity);
    final pal = context.pal;

    Widget pil(String label, bool sel, VoidCallback onTap) => Expanded(
      child: PressableScale(
        scale: .96,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: 180.ms,
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : pal.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? AppColors.primary : pal.outline,
                width: 0.5,
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: sel ? const Color(0xFF2B1B10) : pal.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );

    return AnimatedSize(
      duration: 250.ms,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(14, 4, 14, _recurring ? 14 : 4),
        decoration: BoxDecoration(
          color: pal.field,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: pal.outline, width: 0.5),
        ),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Tagihan rutin (bulanan)',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Otomatis muncul lagi tiap bulan',
                style: AppTextStyles.caption,
              ),
              value: _recurring,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _recurring = v);
              },
            ),
            if (_recurring) ...[
              Row(
                children: [
                  pil(
                    'Tanpa batas',
                    _tanpaBatas,
                    () => setState(() => _tanpaBatas = true),
                  ),
                  const SizedBox(width: 8),
                  pil(
                    'Beberapa bulan',
                    !_tanpaBatas,
                    () => setState(() => _tanpaBatas = false),
                  ),
                ],
              ),
              if (!_tanpaBatas)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: _totalBulanController,
                    keyboardType: TextInputType.number,
                    decoration: appInput('Jumlah bulan', icon: Icons.repeat),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SHEET BAYAR
// ================================================================

class _BayarSheet extends ConsumerStatefulWidget {
  final BillModel bill;

  const _BayarSheet({required this.bill});

  @override
  ConsumerState<_BayarSheet> createState() => _BayarSheetState();
}

class _BayarSheetState extends ConsumerState<_BayarSheet> {
  final _amountController = TextEditingController();
  String? _walletId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = NumberFormat(
      '#,##0',
      'id_ID',
    ).format(widget.bill.amount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _nominal =>
      double.tryParse(
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      ) ??
      0;

  Future<void> _bayar() async {
    if (_walletId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih wallet dulu.')));
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

    final saldo = ref
        .read(walletBalancesProvider)
        .where((b) => b.wallet.id == _walletId)
        .firstOrNull;
    if (saldo != null && amount > saldo.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo ${saldo.wallet.name} tidak cukup. '
            'Kurang ${formatRupiah(amount - saldo.balance)}.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(billsRepositoryProvider)
          .bayarTagihan(widget.bill, _walletId!, nominal: amount);
      ref.invalidate(billsProvider);
      ref.invalidate(transactionsProvider);
      await jadwalkanUlangTagihan(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membayar tagihan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final balances = ref.watch(walletBalancesProvider);
    if (balances.isNotEmpty) _walletId ??= balances.first.wallet.id;

    final terpilih = balances
        .where((b) => b.wallet.id == _walletId)
        .firstOrNull;
    final kurang = terpilih != null && _nominal > terpilih.balance;

    return SheetFrame(
      title: 'Bayar Tagihan',
      subtitle: widget.bill.title,
      icon: Icons.payments_rounded,
      children: [
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [RupiahInputFormatter()],
          onChanged: (_) => setState(() {}),
          decoration: appInput(
            'Nominal dibayar',
            prefix: 'Rp ',
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          children: [
            QuickChip(
              label: 'Sesuai tagihan ${formatRupiah(widget.bill.amount)}',
              onTap: () {
                final t = formatRibuan(widget.bill.amount);
                _amountController.value = TextEditingValue(
                  text: t,
                  selection: TextSelection.collapsed(offset: t.length),
                );
                setState(() {});
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (balances.isEmpty)
          Text(
            'Belum ada wallet. Buat dulu di halaman Akun.',
            style: AppTextStyles.caption,
          )
        else
          _buildWalletCards(balances),
        AnimatedSize(
          duration: 200.ms,
          alignment: Alignment.topCenter,
          child: kurang
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: pal.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Saldo ${terpilih.wallet.name} tidak cukup '
                          '(kurang ${formatRupiah(_nominal - terpilih.balance)}).',
                          style: AppTextStyles.caption.copyWith(
                            color: pal.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 20),
        PrimaryButton(text: 'Bayar', loading: _saving, onPressed: _bayar),
      ],
    );
  }

  Widget _buildWalletCards(List<WalletBalance> balances) {
    final pal = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bayar dari', style: AppTextStyles.caption),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: balances.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final b = balances[i];
              final sel = b.wallet.id == _walletId;
              return PressableScale(
                scale: .96,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _walletId = b.wallet.id);
                  },
                  child: AnimatedContainer(
                    duration: 180.ms,
                    width: 160,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sel ? pal.primaryLight : pal.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? AppColors.primary : pal.outline,
                        width: sel ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          b.wallet.type.icon,
                          size: 20,
                          color: sel ? pal.primaryDark : pal.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.wallet.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                formatRupiah(b.balance),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: 200.ms,
                          transitionBuilder: (c, a) =>
                              ScaleTransition(scale: a, child: c),
                          child: sel
                              ? const Icon(
                                  Icons.check_circle,
                                  key: ValueKey('on'),
                                  size: 18,
                                  color: AppColors.primary,
                                )
                              : const SizedBox(key: ValueKey('off'), width: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
