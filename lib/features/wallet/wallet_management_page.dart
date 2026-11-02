import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';

import '../../shared/models/wallet_model.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/header_line.dart';
import '../../shared/widgets/pressable_scale.dart';
import '../../shared/widgets/wallet_type_picker.dart';
import '../../shared/widgets/app_form_widgets.dart';
import '../../shared/widgets/primary_button.dart';

import '../onboarding/wallet_setup_form.dart';
import 'wallet_provider.dart';

class WalletManagementPage extends ConsumerWidget {
  const WalletManagementPage({super.key});

  // ============================================================
  // AKSI
  // ============================================================

  void _bukaFormTambah(BuildContext context, WidgetRef ref) {
    showAppSheet(
      context,
      (ctx) => SheetFrame(
        title: 'Tambah Wallet',
        subtitle: 'Pilih jenis dan isi saldo awal',
        icon: Icons.add_card_rounded,
        children: [
          WalletSetupForm(
            onSaved: (_) {
              ref.invalidate(walletsProvider);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _bukaFormEdit(BuildContext context, WidgetRef ref, WalletModel wallet) {
    showAppSheet(context, (_) => _EditWalletSheet(wallet: wallet));
  }

  Future<void> _konfirmasiHapus(
    BuildContext context,
    WidgetRef ref,
    WalletModel wallet,
  ) async {
    final jumlahTransaksi = await ref
        .read(walletRepositoryProvider)
        .hitungTransaksiTerkait(wallet.id);

    if (!context.mounted) return;

    if (jumlahTransaksi > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tidak bisa dihapus'),
          content: Text(
            '"${wallet.name}" masih punya $jumlahTransaksi transaksi terkait. Hapus atau pindahkan transaksinya dulu lewat Riwayat sebelum menghapus wallet ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus "${wallet.name}"?'),
        content: const Text(
          'Wallet ini belum punya transaksi apa pun, aman dihapus.',
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
    if (konfirmasi != true) return;

    try {
      await ref.read(walletRepositoryProvider).deleteWallet(wallet.id);
      ref.invalidate(walletsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus wallet: $e')));
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final balances = ref.watch(walletBalancesProvider);
    final pal = context.pal;
    const tinta = Color(0xFF2B1B10);

    return ColoredBox(
      color: pal.background,
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton:
              FloatingActionButton.extended(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _bukaFormTambah(context, ref);
                    },
                    backgroundColor: AppColors.primary,
                    foregroundColor: tinta,
                    shape: const StadiumBorder(),
                    extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
                    extendedIconLabelSpacing: 8,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      'Tambah Wallet',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tinta,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 350.ms)
                  .scale(
                    begin: const Offset(.6, .6),
                    delay: 350.ms,
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: walletsAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                        error: (err, _) =>
                            Center(child: Text('Gagal memuat data: $err')),
                        data: (wallets) {
                          if (wallets.isEmpty) return _buildEmpty(context);

                          final items = <Widget>[
                            _buildHero(context, balances),
                            const SizedBox(height: 16),
                            ...balances.map(
                              (b) => _buildWalletCard(
                                context,
                                ref,
                                b.wallet,
                                b.balance,
                              ),
                            ),
                          ];

                          return ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            children: items
                                .animate(interval: 50.ms)
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              Text(
                'Kelola Wallet',
                style: AppTextStyles.title.copyWith(fontSize: 20),
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

  Widget _buildHero(BuildContext context, List<WalletBalance> balances) {
    const tinta = Color(0xFF2B1B10);
    final pal = context.pal;
    final total = balances.fold<double>(0, (s, b) => s + b.balance);

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Saldo',
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: tinta,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'dari ${balances.length} wallet',
                  style: AppTextStyles.caption.copyWith(
                    color: tinta.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: tinta,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: 0,
                end: -4,
                duration: 1400.ms,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(
    BuildContext context,
    WidgetRef ref,
    WalletModel wallet,
    double saldo,
  ) {
    final pal = context.pal;
    final warna = warnaJenisWallet(wallet.type);

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
              _bukaFormEdit(context, ref, wallet);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: warna.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(wallet.type.icon, color: warna),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(wallet.type.label, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatRupiah(saldo),
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                          color: saldo < 0 ? pal.error : null,
                        ),
                      ),
                      Text(
                        'Awal ${formatRupiah(wallet.initialBalance)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: pal.textSecondary),
                    color: pal.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: pal.outline, width: 0.5),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _bukaFormEdit(context, ref, wallet);
                      } else if (value == 'hapus') {
                        _konfirmasiHapus(context, ref, wallet);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'hapus',
                        child: Text(
                          'Hapus',
                          style: TextStyle(color: pal.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final pal = context.pal;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pal.primaryLight,
                    border: Border.all(color: pal.outline, width: 0.5),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 40,
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
            const SizedBox(height: 16),
            Text(
              'Belum ada wallet',
              style: AppTextStyles.title.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Tekan Tambah untuk membuat dompet, rekening, atau e-wallet.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SHEET EDIT WALLET
// ================================================================

class _EditWalletSheet extends ConsumerStatefulWidget {
  final WalletModel wallet;

  const _EditWalletSheet({required this.wallet});

  @override
  ConsumerState<_EditWalletSheet> createState() => _EditWalletSheetState();
}

class _EditWalletSheetState extends ConsumerState<_EditWalletSheet> {
  late final TextEditingController _nameController;
  late WalletType _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wallet.name);
    _type = widget.wallet.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama wallet tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ref
          .read(walletRepositoryProvider)
          .updateWallet(
            WalletModel(
              id: widget.wallet.id,
              name: name,
              type: _type,
              initialBalance: widget.wallet.initialBalance,
            ),
          );
      ref.invalidate(walletsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan perubahan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: 'Edit Wallet',
      subtitle: 'Saldo awal tidak bisa diubah, saldo mengikuti transaksi',
      icon: Icons.edit_rounded,
      children: [
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: appInput(
            'Nama Wallet',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(height: 16),
        Text('Jenis Wallet', style: AppTextStyles.title.copyWith(fontSize: 15)),
        const SizedBox(height: 8),
        WalletTypePicker(
          selected: _type,
          onChanged: (t) => setState(() => _type = t),
        ),
        const SizedBox(height: 24),
        PrimaryButton(text: 'Simpan', loading: _saving, onPressed: _simpan),
      ],
    );
  }
}
