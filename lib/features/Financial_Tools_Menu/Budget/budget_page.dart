import '../../../core/utils/category_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_categories.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/rupiah_input_formatter.dart';
import '../../../core/theme/app_palette.dart';

import '../../../shared/models/budget_model.dart';
import '../../../shared/widgets/app_form_widgets.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/header_line.dart';
import '../../../shared/widgets/pressable_scale.dart';

import '../Target/target_form_widgets.dart' show QuickChip;
import '../../transaction/transaction_provider.dart';
import '../../notification/notification_prompt.dart';
import 'budget_provider.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  // ============================================================
  // AKSI
  // ============================================================
  void _bukaFormBudget(
    BuildContext context, {
    BudgetModel? existing,
    String? kategori,
  }) {
    showAppSheet(
      context,
      (_) => _BudgetFormSheet(existing: existing, initialCategory: kategori),
    );
  }

  void _bukaDetail(BuildContext context, BudgetModel budget) {
    showAppSheet(
      context,
      (_) => _BudgetDetailSheet(
        budget: budget,
        onEdit: () => _bukaFormBudget(context, existing: budget),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final pengeluaran = ref.watch(pengeluaranPerKategoriProvider);

    return ColoredBox(
      color: context.pal.background,
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: budgetsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) =>
                        Center(child: Text('Gagal memuat data: $err')),
                    data: (budgets) {
                      if (budgets.isEmpty) return _buildEmpty(context);

                      final totalLimit = budgets.fold<double>(
                        0,
                        (a, b) => a + b.limitAmount,
                      );
                      final totalTerpakai = budgets.fold<double>(
                        0,
                        (a, b) => a + (pengeluaran[b.category] ?? 0),
                      );
                      final adaLimit = budgets.map((b) => b.category).toSet();
                      final tanpaLimit =
                          pengeluaran.entries
                              .where(
                                (e) => !adaLimit.contains(e.key) && e.value > 0,
                              )
                              .toList()
                            ..sort((a, b) => b.value.compareTo(a.value));

                      final items = <Widget>[
                        _buildSummaryCard(context, totalLimit, totalTerpakai),
                        const SizedBox(height: 20),
                        _grupJudul(context, 'Detail Kategori', budgets.length),
                        ...budgets.map(
                          (b) => _buildBudgetCard(
                            context,
                            b,
                            pengeluaran[b.category] ?? 0,
                          ),
                        ),
                        if (tanpaLimit.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _grupJudul(
                            context,
                            'Belum Ada Limit',
                            tanpaLimit.length,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 10,
                              left: 14,
                            ),
                            child: Text(
                              'Pengeluaran ini belum terpantau budget.',
                              style: AppTextStyles.caption,
                            ),
                          ),
                          ...tanpaLimit.map(
                            (e) =>
                                _buildTanpaLimitCard(context, e.key, e.value),
                          ),
                        ],
                      ];

                      return ListView(
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
                            text: 'Tambah Budget Baru',
                            leading: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => _bukaFormBudget(context),
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

  Widget _grupJudul(BuildContext context, String judul, int n) {
    final pal = context.pal;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget/Limit',
                      style: AppTextStyles.title.copyWith(fontSize: 20),
                    ),
                  ],
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

  Widget _buildEmpty(BuildContext context) {
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
                    Icons.pie_chart_outline,
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
              'Belum ada budget',
              style: AppTextStyles.title.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Tekan "Tambah Budget Baru" untuk menetapkan limit per kategori.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  // ---------- KARTU RINGKASAN (hero amber) ----------
  Widget _buildSummaryCard(
    BuildContext context,
    double totalLimit,
    double terpakai,
  ) {
    const tinta = Color(0xFF2B1B10);
    final pal = context.pal;
    final sisa = totalLimit - terpakai;
    final persen = totalLimit <= 0 ? 0.0 : terpakai / totalLimit;
    final over = persen > 1;

    final labelStatus = over
        ? 'Melebihi Batas'
        : persen >= 0.8
        ? 'Hampir Batas'
        : 'Batas Aman';
    final ikonStatus = over
        ? Icons.warning_amber_rounded
        : persen >= 0.8
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Budget Bulan Ini',
                      style: AppTextStyles.caption.copyWith(
                        color: tinta.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: totalLimit),
                      duration: 900.ms,
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => Text(
                        formatRupiah(v),
                        style: AppTextStyles.title.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: tinta,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Cincin persen terpakai
              TweenAnimationBuilder<double>(
                tween: Tween(end: persen),
                duration: 1000.ms,
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: v.clamp(0.0, 1.0).toDouble(),
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white.withValues(alpha: 0.45),
                          color: over ? AppColors.error : tinta,
                        ),
                      ),
                      Text(
                        '${(v * 100).round()}%',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                          color: tinta,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              kotak('Terpakai', formatRupiah(terpakai)),
              const SizedBox(width: 10),
              kotak('Sisa Budget', formatRupiah(sisa < 0 ? 0 : sisa)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: over
                  ? AppColors.error
                  : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(ikonStatus, size: 15, color: over ? Colors.white : tinta),
                const SizedBox(width: 6),
                Text(
                  labelStatus,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: over ? Colors.white : tinta,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- KARTU PER KATEGORI ----------
  Widget _buildBudgetCard(
    BuildContext context,
    BudgetModel budget,
    double terpakai,
  ) {
    final pal = context.pal;
    final rasio = budget.limitAmount <= 0 ? 0.0 : terpakai / budget.limitAmount;
    final progress = rasio.clamp(0.0, 1.0).toDouble();
    final over = rasio > 1;
    final hampir = !over && rasio >= 0.8;
    final warnaBar = over
        ? pal.error
        : hampir
        ? pal.primaryDark
        : AppColors.primary;
    final warnaStatus = over
        ? pal.error
        : hampir
        ? pal.primaryDark
        : pal.success;
    final labelStatus = over
        ? 'Melebihi'
        : hampir
        ? 'Hampir'
        : 'Aman';
    final warnaKategori = categoryColor(budget.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        scale: .98,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: pal.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: over ? pal.error.withValues(alpha: 0.5) : pal.outline,
              width: over ? 1 : 0.5,
            ),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _bukaDetail(context, budget);
            },
            child: IntrinsicHeight(
              child: Row(
                children: [
                  if (over) Container(width: 5, color: pal.error),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: warnaKategori.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  categoryIcon(budget.category),
                                  color: warnaKategori,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      budget.category,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      over
                                          ? 'Melebihi ${formatRupiah(terpakai - budget.limitAmount)}'
                                          : 'Sisa ${formatRupiah(budget.limitAmount - terpakai)}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: over
                                            ? pal.error
                                            : pal.textSecondary,
                                        fontWeight: over
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatRupiah(terpakai),
                                    style: AppTextStyles.title.copyWith(
                                      fontSize: 16,
                                      color: over ? pal.error : null,
                                    ),
                                  ),
                                  Text(
                                    '/ ${formatRupiah(budget.limitAmount)}',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TweenAnimationBuilder<double>(
                            tween: Tween(end: progress),
                            duration: 900.ms,
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: v,
                                    minHeight: 10,
                                    backgroundColor: pal.border,
                                    color: warnaBar,
                                  ),
                                ),
                                // Penanda batas peringatan 80% (Alignment x = 0.6 → 80% lebar)
                                Positioned.fill(
                                  child: Align(
                                    alignment: const Alignment(0.6, 0),
                                    child: Container(
                                      width: 2,
                                      color: pal.textSecondary.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: warnaStatus.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  labelStatus,
                                  style: AppTextStyles.caption.copyWith(
                                    color: warnaStatus,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(rasio * 100).round()}%',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: warnaBar,
                                ),
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
    );
  }

  Widget _buildTanpaLimitCard(
    BuildContext context,
    String kategori,
    double terpakai,
  ) {
    final pal = context.pal;
    final warna = categoryColor(kategori);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: pal.outline, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(categoryIcon(kategori), color: warna, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kategori,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Terpakai ${formatRupiah(terpakai)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            PressableScale(
              scale: .94,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _bukaFormBudget(context, kategori: kategori);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: pal.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: pal.outline, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: pal.primaryDark),
                      const SizedBox(width: 4),
                      Text(
                        'Set limit',
                        style: AppTextStyles.caption.copyWith(
                          color: pal.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// FORM BUDGET (BARU & EDIT)
// ================================================================

class _BudgetFormSheet extends ConsumerStatefulWidget {
  final BudgetModel? existing;
  final String? initialCategory;

  const _BudgetFormSheet({this.existing, this.initialCategory});

  @override
  ConsumerState<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<_BudgetFormSheet> {
  late final TextEditingController _amountController;
  String? _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category ?? widget.initialCategory;
    _amountController = TextEditingController(
      text: widget.existing != null
          ? NumberFormat('#,##0', 'id_ID').format(widget.existing!.limitAmount)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final amount =
        double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    if (_category == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih kategori dulu.')));
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal limit wajib diisi.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ref
          .read(budgetRepositoryProvider)
          .setBudget(
            BudgetModel(
              id: widget.existing?.id ?? '',
              category: _category!,
              limitAmount: amount,
            ),
          );
      ref.invalidate(budgetsProvider);

      if (widget.existing == null) {
        if (!mounted) return;
        try {
          await tawarkanNotif(context, ref, JenisReminder.budget);
        } catch (_) {
          // Masalah notifikasi tidak boleh membuat budget terlihat gagal.
        }
      }
      await jadwalkanUlangSemua(ref);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Budget disimpan.')));
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan budget: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _hapus() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus budget "${widget.existing!.category}"?'),
        content: const Text(
          'Limit kategori ini dihapus. Transaksi tidak terpengaruh.',
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
      await ref.read(budgetRepositoryProvider).hapusBudget(widget.existing!.id);
      ref.invalidate(budgetsProvider);
      await jadwalkanUlangSemua(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus budget: $e')));
      }
    }
  }

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

  Widget _buildKategoriPicker(List<String> pilihan, bool isEdit) {
    final pal = context.pal;
    if (pilihan.isEmpty) {
      return Text(
        'Semua kategori sudah punya budget.',
        style: AppTextStyles.caption,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: AppTextStyles.caption),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pilihan.map((label) {
            final sel = label == _category;
            final warna = categoryColor(label);
            return PressableScale(
              scale: .94,
              enabled: !isEdit,
              child: GestureDetector(
                onTap: isEdit
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() => _category = label);
                      },
                child: AnimatedContainer(
                  duration: 180.ms,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                        categoryIcon(label),
                        size: 16,
                        color: sel ? Colors.white : warna,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
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
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final isEdit = widget.existing != null;

    final sudahAda = (ref.watch(budgetsProvider).valueOrNull ?? [])
        .map((b) => b.category)
        .toSet();
    final pilihan = isEdit
        ? [widget.existing!.category]
        : AppCategories.expense
              .map((c) => c.label)
              .where((c) => !sudahAda.contains(c))
              .toList();

    // Saran: pengeluaran bulan ini pada kategori terpilih.
    final pengeluaran = ref.watch(pengeluaranPerKategoriProvider);
    final terpakaiKat = _category == null
        ? 0.0
        : (pengeluaran[_category] ?? 0.0);

    return SheetFrame(
      title: isEdit ? 'Edit Budget' : 'Budget Baru',
      subtitle: 'Tetapkan limit pengeluaran per bulan',
      icon: isEdit ? Icons.edit_rounded : Icons.pie_chart_rounded,
      children: [
        _buildKategoriPicker(pilihan, isEdit),
        const SizedBox(height: 14),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [RupiahInputFormatter()],
          onChanged: (_) => setState(() {}),
          decoration: appInput(
            'Limit per bulan',
            prefix: 'Rp ',
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            QuickChip(label: '+100rb', onTap: () => _tambah(100000)),
            QuickChip(label: '+500rb', onTap: () => _tambah(500000)),
            QuickChip(label: '+1jt', onTap: () => _tambah(1000000)),
            if (terpakaiKat > 0)
              QuickChip(
                label: 'Sesuai pemakaian',
                onTap: () {
                  final t = formatRibuan(terpakaiKat);
                  _amountController.value = TextEditingValue(
                    text: t,
                    selection: TextSelection.collapsed(offset: t.length),
                  );
                  setState(() {});
                },
              ),
          ],
        ),
        AnimatedSize(
          duration: 220.ms,
          alignment: Alignment.topCenter,
          child: terpakaiKat > 0
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: pal.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: pal.primaryDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bulan ini kamu sudah memakai ${formatRupiah(terpakaiKat)} di $_category.',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 20),
        PrimaryButton(text: 'Simpan', loading: _saving, onPressed: _simpan),
        if (isEdit)
          Center(
            child: TextButton.icon(
              onPressed: _hapus,
              icon: Icon(Icons.delete_outline, color: pal.error, size: 18),
              label: Text('Hapus Budget', style: TextStyle(color: pal.error)),
            ),
          ),
      ],
    );
  }
}

// ================================================================
// RINCIAN KATEGORI
// ================================================================

class _BudgetDetailSheet extends ConsumerWidget {
  final BudgetModel budget;
  final VoidCallback onEdit;

  const _BudgetDetailSheet({required this.budget, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    final now = DateTime.now();
    final semua = ref.watch(transactionsProvider).valueOrNull ?? [];
    final transaksi =
        semua
            .where(
              (t) =>
                  t.category == budget.category &&
                  t.amount < 0 &&
                  t.transactionDate.year == now.year &&
                  t.transactionDate.month == now.month,
            )
            .toList()
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    final terpakai = transaksi.fold<double>(0, (a, t) => a + t.amount.abs());
    final sisa = budget.limitAmount - terpakai;
    final rasio = budget.limitAmount <= 0 ? 0.0 : terpakai / budget.limitAmount;
    final over = rasio > 1;
    final rata = terpakai / now.day;
    final sisaHari =
        DateUtils.getDaysInMonth(now.year, now.month) - now.day + 1;
    final amanPerHari = sisa > 0 ? sisa / sisaHari : 0.0;
    final warna = categoryColor(budget.category);

    Widget info(String label, String nilai, {Color? warnaNilai}) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: pal.field,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: pal.outline, width: 0.5),
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
                color: warnaNilai,
              ),
            ),
          ],
        ),
      ),
    );

    return SheetFrame(
      title: budget.category,
      subtitle:
          '${formatRupiah(terpakai)} dari ${formatRupiah(budget.limitAmount)} bulan ini',
      icon: categoryIcon(budget.category),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: rasio.clamp(0.0, 1.0).toDouble()),
          duration: 800.ms,
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 10,
              backgroundColor: pal.border,
              color: over ? pal.error : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(rasio * 100).round()}% terpakai',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: over ? pal.error : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            info('Rata-rata/hari', formatRupiah(rata)),
            const SizedBox(width: 10),
            info(
              sisa >= 0 ? 'Aman/hari' : 'Melebihi',
              sisa >= 0 ? formatRupiah(amanPerHari) : formatRupiah(-sisa),
              warnaNilai: sisa >= 0 ? pal.success : pal.error,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Transaksi bulan ini',
          style: AppTextStyles.title.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (transaksi.isEmpty)
          Text('Belum ada pengeluaran.', style: AppTextStyles.caption)
        else
          ...transaksi
              .take(15)
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
                          categoryIcon(budget.category),
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
        if (transaksi.length > 15)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'dan ${transaksi.length - 15} transaksi lainnya',
              style: AppTextStyles.caption,
            ),
          ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: 'Edit Limit',
          onPressed: () {
            Navigator.pop(context);
            onEdit();
          },
        ),
      ],
    );
  }
}
