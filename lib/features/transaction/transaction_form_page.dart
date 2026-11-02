import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_categories.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/category_style.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/rupiah_input_formatter.dart';

import '../../shared/models/budget_model.dart';
import '../../shared/models/transaction_model.dart';
import '../../shared/models/wallet_model.dart';
import '../../shared/widgets/app_form_widgets.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/header_line.dart';
import '../../shared/widgets/pressable_scale.dart';

import '../Financial_Tools_Menu/Budget/budget_provider.dart';
import '../notification/notification_prompt.dart';
import '../wallet/wallet_provider.dart';
import 'transaction_provider.dart';

typedef _BudgetHitung = ({double limit, double terpakai, double proyeksi});

class TransactionFormPage extends ConsumerStatefulWidget {
  final TransactionModel? existing;

  const TransactionFormPage({super.key, this.existing});

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  static const _batasKategori = 8;
  static const _nominalCepat = [10000, 20000, 50000, 100000];

  bool _isPengeluaran = true;
  final _nominalController = TextEditingController();
  final _catatanController = TextEditingController();

  String _kategori = '';
  String? _walletId;
  String? _walletDefault;
  DateTime _tanggal = DateTime.now();
  bool _saving = false;
  bool _sudahSimpan = false;
  bool _semuaKategori = false;

  Uint8List? _fotoBytes;
  String? _fotoUrlLama;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _isPengeluaran = t.amount < 0;
      _nominalController.text = _formatAngka(t.amount.abs());
      _catatanController.text = t.title == t.category ? '' : t.title;
      _kategori = t.category;
      _walletId = t.walletId;
      _tanggal = t.transactionDate;
      _fotoUrlLama = t.imageUrl;
    } else {
      _kategori = AppCategories.expense.first.label;
    }
    final idx = _kategoriAktif.indexWhere((k) => k.label == _kategori);
    _semuaKategori = idx >= _batasKategori;
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  // ============================================================
  // HELPER
  // ============================================================

  List<AppCategory> get _kategoriAktif =>
      _isPengeluaran ? AppCategories.expense : AppCategories.income;

  double get _nominal =>
      double.tryParse(
        _nominalController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      ) ??
      0;

  String _formatAngka(double v) => NumberFormat('#,##0', 'id_ID').format(v);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _adaPerubahan() {
    final catatan = _catatanController.text.trim();
    final t = widget.existing;
    if (t == null) {
      return _nominal > 0 ||
          catatan.isNotEmpty ||
          _fotoBytes != null ||
          !_isPengeluaran ||
          _kategori != AppCategories.expense.first.label ||
          _walletId != _walletDefault ||
          !_sameDay(_tanggal, DateTime.now());
    }
    return _nominal != t.amount.abs() ||
        _isPengeluaran != (t.amount < 0) ||
        _kategori != t.category ||
        _walletId != t.walletId ||
        !_sameDay(_tanggal, t.transactionDate) ||
        catatan != (t.title == t.category ? '' : t.title) ||
        _fotoBytes != null ||
        _fotoUrlLama != t.imageUrl;
  }

  /// Saldo wallet terpilih, di luar transaksi yang sedang diedit.
  double? _saldoTersedia(List<WalletBalance> balances) {
    final cocok = balances.where((b) => b.wallet.id == _walletId);
    if (cocok.isEmpty) return null;
    var saldo = cocok.first.balance;
    final t = widget.existing;
    if (t != null && t.walletId == _walletId) saldo -= t.amount;
    return saldo;
  }

  /// Proyeksi pengeluaran kategori bulan ini. Null kalau budget tidak berlaku.
  _BudgetHitung? _hitungBudget(
    List<BudgetModel> budgets,
    List<TransactionModel> semua,
    double nominal,
  ) {
    if (!_isPengeluaran) return null;
    final now = DateTime.now();
    if (_tanggal.year != now.year || _tanggal.month != now.month) return null;

    final cocok = budgets.where((b) => b.category == _kategori);
    if (cocok.isEmpty) return null;
    final limit = cocok.first.limitAmount;
    if (limit <= 0) return null;

    final terpakai = semua
        .where(
          (t) =>
              t.id != widget.existing?.id &&
              t.category == _kategori &&
              t.amount < 0 &&
              t.transactionDate.year == now.year &&
              t.transactionDate.month == now.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    return (limit: limit, terpakai: terpakai, proyeksi: terpakai + nominal);
  }

  Future<bool> _konfirmasi({
    required String judul,
    required String isi,
    required String ya,
    String batal = 'Batal',
  }) async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(batal),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ya),
          ),
        ],
      ),
    );
    return hasil ?? false;
  }

  Future<bool> _konfirmasiBuang() => _konfirmasi(
    judul: 'Buang perubahan?',
    isi: 'Data yang sudah kamu isi belum disimpan.',
    ya: 'Buang',
    batal: 'Lanjut Isi',
  );

  // ============================================================
  // AKSI
  // ============================================================

  void _tambahNominal(int tambah) {
    HapticFeedback.selectionClick();
    final baru = _formatAngka(_nominal + tambah);
    _nominalController.value = TextEditingValue(
      text: baru,
      selection: TextSelection.collapsed(offset: baru.length),
    );
    setState(() {});
  }

  void _kosongkanNominal() {
    _nominalController.clear();
    setState(() {});
  }

  Future<void> _pilihTanggal() async {
    final hasil = await pilihTanggalApp(
      context,
      initial: _tanggal,
      first: DateTime(2020),
    );
    if (hasil != null) setState(() => _tanggal = hasil);
  }

  Future<void> _ambilFoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _fotoBytes = bytes);
  }

  void _hapusFoto() {
    setState(() {
      _fotoBytes = null;
      _fotoUrlLama = null;
    });
  }

  void _pilihSumberFoto() {
    final adaFoto = _fotoBytes != null || _fotoUrlLama != null;
    showAppSheet(
      context,
      (ctx) => SheetFrame(
        title: 'Foto Bukti',
        subtitle: 'Lampirkan struk atau bukti transaksi',
        children: [
          _opsiSheet(
            ctx,
            Icons.photo_library_outlined,
            'Pilih dari galeri',
            () => _ambilFoto(ImageSource.gallery),
          ),
          _opsiSheet(
            ctx,
            Icons.photo_camera_outlined,
            'Ambil foto',
            () => _ambilFoto(ImageSource.camera),
          ),
          if (adaFoto)
            _opsiSheet(
              ctx,
              Icons.delete_outline,
              'Hapus foto',
              _hapusFoto,
              merah: true,
            ),
        ],
      ),
    );
  }

  Widget _opsiSheet(
    BuildContext ctx,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool merah = false,
  }) {
    final warna = merah ? ctx.pal.error : ctx.pal.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: warna),
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: warna,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
    );
  }

  Future<bool> _cekBudgetSebelumSimpan(double nominal) async {
    final budgets = await ref.read(budgetsProvider.future);
    final semua = await ref.read(transactionsProvider.future);
    final h = _hitungBudget(budgets, semua, nominal);
    if (h == null) return true;

    final persen = h.proyeksi / h.limit;
    if (persen < 0.8) return true;
    if (!mounted) return false;

    return _konfirmasi(
      judul: persen > 1 ? 'Melebihi limit budget' : 'Mendekati limit budget',
      isi:
          'Transaksi ini membuat pengeluaran "$_kategori" bulan ini menjadi '
          '${formatRupiah(h.proyeksi)} dari limit ${formatRupiah(h.limit)} '
          '(${(persen * 100).round()}%).\n\nLanjutkan simpan?',
      ya: 'Lanjutkan',
    );
  }

  Future<void> _simpan() async {
    final nominal = _nominal;

    if (_walletId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih sumber dana dulu.')));
      return;
    }
    if (nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0.')),
      );
      return;
    }

    // Saldo tidak cukup: peringatkan, tapi tetap boleh (mis. mencatat
    // pengeluaran lama).
    final saldo = _saldoTersedia(ref.read(walletBalancesProvider));
    if (_isPengeluaran && saldo != null && nominal > saldo) {
      final lanjut = await _konfirmasi(
        judul: 'Saldo tidak cukup',
        isi:
            'Saldo tersedia ${formatRupiah(saldo)}, sedangkan pengeluaran '
            '${formatRupiah(nominal)}. Saldo wallet akan menjadi minus.\n\n'
            'Tetap simpan?',
        ya: 'Tetap Simpan',
      );
      if (!lanjut) return;
    }

    if (!mounted) return;
    if (!await _cekBudgetSebelumSimpan(nominal)) return;

    setState(() => _saving = true);

    try {
      final repo = ref.read(transactionRepositoryProvider);

      String? fotoUrl = _fotoUrlLama;
      if (_fotoBytes != null) {
        final namaFile = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        fotoUrl = await repo.uploadFoto(_fotoBytes!, namaFile);
      }

      final catatan = _catatanController.text.trim();
      final transaksi = TransactionModel(
        id: widget.existing?.id ?? '',
        title: catatan.isNotEmpty ? catatan : _kategori,
        category: _kategori,
        walletId: _walletId!,
        amount: _isPengeluaran ? -nominal : nominal,
        transactionDate: _tanggal,
        imageUrl: fotoUrl,
      );

      if (widget.existing != null) {
        await repo.updateTransaction(transaksi);
      } else {
        await repo.addTransaction(transaksi);
      }
      ref.invalidate(transactionsProvider);

      // Pengingat catat & budget bergantung pada transaksi terbaru.
      await jadwalkanUlangSemua(ref);

      if (!mounted) return;
      setState(() => _sudahSimpan = true);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existing == null
                ? 'Transaksi disimpan.'
                : 'Perubahan disimpan.',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan transaksi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);
    final balances = ref.watch(walletBalancesProvider);
    final budgets =
        ref.watch(budgetsProvider).valueOrNull ?? const <BudgetModel>[];
    final semuaTrx =
        ref.watch(transactionsProvider).valueOrNull ??
        const <TransactionModel>[];

    if (balances.isNotEmpty && !balances.any((b) => b.wallet.id == _walletId)) {
      _walletId = balances.first.wallet.id;
      if (widget.existing == null) _walletDefault = _walletId;
    }

    final saldo = _saldoTersedia(balances);
    final budget = _hitungBudget(budgets, semuaTrx, _nominal);

    return PopScope(
      canPop: _sudahSimpan || !_adaPerubahan(),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _konfirmasiBuang() && mounted) {
          setState(() => _sudahSimpan = true);
          // ignore: use_build_context_synchronously
          context.pop();
        }
      },
      child: ColoredBox(
        color: context.pal.background,
        child: AppBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      // Jumlah & urutan item tetap (budget pakai slot), jadi
                      // animasi masuk hanya main sekali.
                      children:
                          <Widget>[
                                _buildToggle(),
                                const SizedBox(height: 14),
                                _buildNominalCard(saldo),
                                _buildKategori(),
                                _buildBudgetSlot(budget),
                                _judul('Sumber Dana'),
                                walletsAsync.when(
                                  loading: () =>
                                      const LinearProgressIndicator(),
                                  error: (e, _) => Text(
                                    'Gagal memuat wallet: $e',
                                    style: AppTextStyles.caption,
                                  ),
                                  data: (wallets) {
                                    if (wallets.isEmpty) {
                                      return OutlinedButton.icon(
                                        onPressed: () =>
                                            context.push('/wallets'),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: context.pal.outline,
                                            width: 0.5,
                                          ),
                                          shape: const StadiumBorder(),
                                        ),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Buat wallet dulu'),
                                      );
                                    }
                                    return _buildWalletList(balances);
                                  },
                                ),
                                _judul('Tanggal'),
                                _buildTanggal(),
                                _judul('Catatan'),
                                TextField(
                                  controller: _catatanController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  minLines: 1,
                                  maxLines: 3,
                                  onChanged: (_) => setState(() {}),
                                  decoration: appInput(
                                    'Catatan (opsional)',
                                    icon: Icons.notes_outlined,
                                  ),
                                ),
                                _judul('Foto Bukti'),
                                _buildFoto(),
                              ]
                              .animate(interval: 50.ms)
                              .fadeIn(duration: 350.ms)
                              .slideY(
                                begin: .08,
                                end: 0,
                                duration: 420.ms,
                                curve: Curves.easeOutCubic,
                              ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child:
                        PressableScale(
                              scale: .98,
                              enabled: !_saving,
                              child: PrimaryButton(
                                text: widget.existing == null
                                    ? 'Simpan Transaksi'
                                    : 'Simpan Perubahan',
                                leading: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                ),
                                loading: _saving,
                                onPressed: _simpan,
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 500.ms, duration: 350.ms)
                            .slideY(
                              begin: .6,
                              end: 0,
                              delay: 500.ms,
                              duration: 450.ms,
                              curve: Curves.easeOutCubic,
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

  Widget _judul(String teks) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
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
        Text(teks, style: AppTextStyles.title.copyWith(fontSize: 16)),
      ],
    ),
  );

  Widget _buildHeader() {
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
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).maybePop();
                  },
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
                  widget.existing == null
                      ? 'Catat Transaksi'
                      : 'Edit Transaksi',
                  style: AppTextStyles.title.copyWith(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: HeaderLine(),
        ),
      ],
    );
  }

  // ---------- TOGGLE PENGELUARAN / PEMASUKAN ----------
  Widget _buildToggle() {
    Widget tombol(String label, IconData icon, bool value) {
      final selected = _isPengeluaran == value;
      final warna = selected
          ? const Color(0xFF2B1B10)
          : context.pal.textSecondary;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_isPengeluaran == value) return;
            HapticFeedback.selectionClick();
            setState(() {
              _isPengeluaran = value;
              _kategori = _kategoriAktif.first.label;
              _semuaKategori = false;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: warna),
                  duration: 200.ms,
                  builder: (_, c, _) => Icon(icon, size: 18, color: c),
                ),
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: 200.ms,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: warna,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.pal.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.pal.outline, width: 0.5),
      ),
      child: Stack(
        children: [
          // Pill amber yang meluncur ke sisi aktif.
          Positioned.fill(
            child: AnimatedAlign(
              duration: 280.ms,
              curve: Curves.easeOutCubic,
              alignment: Alignment(_isPengeluaran ? -1 : 1, 0),
              child: FractionallySizedBox(
                widthFactor: .5,
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
            children: [
              tombol('Pengeluaran', Icons.arrow_upward_rounded, true),
              tombol('Pemasukan', Icons.arrow_downward_rounded, false),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- KARTU NOMINAL ----------
  Widget _buildNominalCard(double? saldo) {
    final nominal = _nominal;
    final kurang = _isPengeluaran && saldo != null && nominal > saldo;
    final tone = _isPengeluaran ? context.pal.error : context.pal.success;

    return AnimatedContainer(
      duration: 250.ms,
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.pal.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: kurang ? context.pal.error : context.pal.outline,
          width: kurang ? 1.2 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Nominal', style: AppTextStyles.caption),
              const Spacer(),
              AnimatedSwitcher(
                duration: 220.ms,
                child: Container(
                  key: ValueKey(_isPengeluaran),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPengeluaran
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 13,
                        color: tone,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isPengeluaran ? 'Pengeluaran' : 'Pemasukan',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tone,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Rp',
                style: AppTextStyles.heading.copyWith(
                  fontSize: 22,
                  color: context.pal.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _nominalController,
                  autofocus: widget.existing == null,
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahInputFormatter()],
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: kurang ? context.pal.error : null,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: AppTextStyles.heading.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: context.pal.textSecondary.withValues(alpha: 0.4),
                    ),
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              if (nominal > 0)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: context.pal.textSecondary,
                  ),
                  onPressed: _kosongkanNominal,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _nominalCepat.map((n) {
              return PressableScale(
                scale: .92,
                child: GestureDetector(
                  onTap: () => _tambahNominal(n),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.pal.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.pal.outline,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '+${n ~/ 1000}rb',
                      style: AppTextStyles.caption.copyWith(
                        color: context.pal.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_isPengeluaran && saldo != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(
                    kurang
                        ? Icons.warning_amber_rounded
                        : Icons.account_balance_wallet_outlined,
                    size: 14,
                    color: kurang
                        ? context.pal.error
                        : context.pal.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      kurang
                          ? 'Saldo tidak cukup (tersedia ${formatRupiah(saldo)})'
                          : 'Saldo tersedia ${formatRupiah(saldo)}',
                      style: AppTextStyles.caption.copyWith(
                        color: kurang ? context.pal.error : null,
                        fontWeight: kurang ? FontWeight.w700 : FontWeight.w400,
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

  // ---------- KATEGORI (grid) ----------
  Widget _buildKategori() {
    final semua = _kategoriAktif;
    final bisaLipat = semua.length > _batasKategori;
    final tampil = (_semuaKategori || !bisaLipat)
        ? semua
        : semua.take(_batasKategori).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Kategori',
                  style: AppTextStyles.title.copyWith(fontSize: 16),
                ),
              ),
              if (bisaLipat)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () =>
                      setState(() => _semuaKategori = !_semuaKategori),
                  child: Text(_semuaKategori ? 'Ringkas' : 'Lihat Semua'),
                ),
            ],
          ),
        ),
        AnimatedSize(
          duration: 250.ms,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: 220.ms,
            child: GridView.count(
              key: ValueKey('$_isPengeluaran-$_semuaKategori'),
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 0.82,
              children: tampil.map((k) {
                final selected = _kategori == k.label;
                final warna = categoryColor(k.label);
                return PressableScale(
                  scale: .92,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _kategori = k.label);
                    },
                    child: Column(
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.1 : 1,
                          duration: 220.ms,
                          curve: Curves.easeOutBack,
                          child: AnimatedContainer(
                            duration: 180.ms,
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: selected
                                  ? warna
                                  : warna.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? context.pal.outline
                                    : Colors.transparent,
                                width: 0.5,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: warna.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : const [],
                            ),
                            child: Icon(
                              k.icon,
                              color: selected ? Colors.white : warna,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          k.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: selected ? context.pal.textPrimary : null,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- INFO BUDGET ----------
  Widget _buildBudgetInfo(_BudgetHitung h) {
    final persen = h.proyeksi / h.limit;
    final over = persen > 1;
    final warna = over
        ? context.pal.error
        : persen >= 0.8
        ? context.pal.primaryDark
        : context.pal.success;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: warna.withValues(alpha: 0.35), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline, size: 16, color: warna),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Budget $_kategori',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(persen * 100).round()}%',
                style: AppTextStyles.caption.copyWith(
                  color: warna,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: persen.clamp(0.0, 1.0).toDouble(),
            ),
            duration: 500.ms,
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: context.pal.border,
                color: warna,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            over
                ? 'Melebihi limit ${formatRupiah(h.proyeksi - h.limit)}'
                : 'Sisa ${formatRupiah(h.limit - h.proyeksi)} dari ${formatRupiah(h.limit)}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSlot(_BudgetHitung? h) {
    return AnimatedSize(
      duration: 250.ms,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: h == null
          ? const SizedBox(width: double.infinity, height: 0)
          : _buildBudgetInfo(h),
    );
  }

  // ---------- SUMBER DANA ----------
  Widget _buildWalletList(List<WalletBalance> balances) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: balances.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final b = balances[i];
          final selected = b.wallet.id == _walletId;
          return PressableScale(
            scale: .96,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _walletId = b.wallet.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? context.pal.primaryLight : context.pal.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : context.pal.outline,
                    width: selected ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      b.wallet.type.icon,
                      size: 20,
                      color: selected
                          ? context.pal.primaryDark
                          : context.pal.textSecondary,
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
                      child: selected
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
    );
  }

  // ---------- TANGGAL ----------
  Widget _buildTanggal() {
    final now = DateTime.now();
    final hariIni = _sameDay(_tanggal, now);
    final kemarin = _sameDay(_tanggal, now.subtract(const Duration(days: 1)));
    final lain = !hariIni && !kemarin;

    Widget pil(
      String label,
      bool selected,
      VoidCallback onTap, {
      IconData? icon,
    }) {
      final warna = selected
          ? const Color(0xFF2B1B10)
          : context.pal.textSecondary;
      return PressableScale(
        scale: .94,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : context.pal.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : context.pal.outline,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: warna),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: warna,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        pil(
          'Hari Ini',
          hariIni,
          () => setState(() => _tanggal = DateTime.now()),
        ),
        pil(
          'Kemarin',
          kemarin,
          () => setState(
            () => _tanggal = DateTime.now().subtract(const Duration(days: 1)),
          ),
        ),
        pil(
          lain
              ? DateFormat('d MMM yyyy', 'id_ID').format(_tanggal)
              : 'Pilih Tanggal',
          lain,
          _pilihTanggal,
          icon: Icons.calendar_today_outlined,
        ),
      ],
    );
  }

  // ---------- FOTO BUKTI ----------
  Widget _buildFoto() {
    final ada = _fotoBytes != null || _fotoUrlLama != null;

    return GestureDetector(
      onTap: _pilihSumberFoto,
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOutCubic,
        width: double.infinity,
        height: ada ? 170 : 96,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.pal.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.pal.outline, width: 0.5),
        ),
        child: ada
            ? Stack(
                fit: StackFit.expand,
                children: [
                  _fotoBytes != null
                      ? Image.memory(_fotoBytes!, fit: BoxFit.cover)
                      : Image.network(
                          _fotoUrlLama!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: context.pal.textSecondary,
                            ),
                          ),
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Ubah',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: context.pal.primaryDark,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tambah foto bukti (opsional)',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
      ),
    );
  }
}
