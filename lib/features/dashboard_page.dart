import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth/auth_provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text.dart';
import '../core/utils/category_style.dart';
import '../core/theme/app_palette.dart';

import '../shared/models/transaction_model.dart';
import 'package:didigo/shared/widgets/transaction_tile.dart';
import '../shared/widgets/animated_count.dart';
import '../shared/widgets/app_card.dart';
import '../shared/widgets/pressable_scale.dart';
import '../shared/models/wallet_model.dart';
import '../shared/widgets/app_background.dart';
import '../../shared/widgets/header_line.dart';

import '../features/notification/notification_provider.dart';
import 'notification/notification_prompt.dart';
import 'transaction/transaction_provider.dart';
import 'wallet/wallet_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _saldoVisible = true;

  static const _financialTools = [
    {'label': 'Target', 'icon': Icons.track_changes_outlined},
    {'label': 'Tagihan', 'icon': Icons.receipt_long_outlined},
    {'label': 'Budget/Limit', 'icon': Icons.pie_chart_outline},
    {'label': 'Laporan', 'icon': Icons.edit_note_outlined},
  ];

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).logout();
    if (mounted) context.go('/login');
  }

  String _rupiah(double value) {
    final isNegatif = value < 0;
    final absValue = value.abs().toStringAsFixed(0);
    final withDots = absValue.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '${isNegatif ? '-' : ''}Rp$withDots';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jadwalkanNotifikasi());
  }

  Future<void> _jadwalkanNotifikasi() async {
    await jadwalkanUlangSemua(ref);
  }

  @override
  Widget build(BuildContext context) {
    final transaksiAsync = ref.watch(transactionsProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: transaksiAsync.when(
            loading: () => _buildSkeleton(),
            error: (err, _) => Center(child: Text('Gagal memuat data: $err')),
            data: (transaksi) => _buildContent(transaksi),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Skeleton loading
  // ---------------------------------------------------------------------------

  Widget _skeletonBox(double h, {double? w, double r = 16}) {
    final box = Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: context.pal.border,
        borderRadius: BorderRadius.circular(r),
      ),
    );
    // ListView memaksa lebar penuh; Align membuat width benar-benar dipakai.
    return w == null ? box : Align(alignment: Alignment.centerLeft, child: box);
  }

  Widget _buildSkeleton() {
    Widget twoBoxes(double h) => Row(
      children: [
        Expanded(child: _skeletonBox(h)),
        const SizedBox(width: 8),
        Expanded(child: _skeletonBox(h)),
      ],
    );

    return ListView(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _skeletonBox(44, w: 220),
            const SizedBox(height: 16),
            _skeletonBox(130, r: 20),
            const SizedBox(height: 12),
            twoBoxes(64),
            const SizedBox(height: 15),
            _skeletonBox(18, w: 160),
            const SizedBox(height: 8),
            twoBoxes(90),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (_) => _skeletonBox(56, w: 56)),
            ),
            const SizedBox(height: 24),
            _skeletonBox(80, r: 20),
            const SizedBox(height: 24),
            for (var i = 0; i < 3; i++) ...[
              _skeletonBox(64),
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

  // ---------------------------------------------------------------------------
  // Konten
  // ---------------------------------------------------------------------------

  Widget _buildContent(List<TransactionModel> transaksi) {
    final saldo = ref.watch(saldoProvider);
    final ringkasan = ref.watch(ringkasanBulanIniProvider);
    final walletBalances = ref.watch(walletBalancesProvider);
    final transaksiTerakhir = transaksi.take(5).toList();
    final streak = ref.watch(streakProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children:
          <Widget>[
                _buildHeader(),
                const SizedBox(height: 16),
                _buildSaldoCard(saldo),
                const SizedBox(height: 12),
                _buildRekeningRow(walletBalances),
                const SizedBox(height: 15),
                Text('Ringkasan Bulan Ini', style: AppTextStyles.title),
                const SizedBox(height: 8),
                _buildRingkasanRow(ringkasan.pemasukan, ringkasan.pengeluaran),
                const SizedBox(height: 15),
                Text('Financial Tools', style: AppTextStyles.title),
                const SizedBox(height: 8),
                _buildFinancialTools(),
                const SizedBox(height: 24),
                _buildStreakBanner(streak),
                const SizedBox(height: 24),
                Text('Transaksi Terakhir', style: AppTextStyles.title),
                const SizedBox(height: 8),
                if (transaksiTerakhir.isEmpty)
                  Text('Belum ada transaksi.', style: AppTextStyles.body)
                else
                  ...transaksiTerakhir.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PressableScale(
                        scale: .97,
                        child: TransactionTile(
                          transaction: t,
                          borderColor: Colors.black,
                          showDate: true,
                        ),
                      ),
                    ),
                  ),
              ]
              .animate(interval: 55.ms)
              .fadeIn(duration: 380.ms)
              .slideY(
                begin: .12,
                end: 0,
                duration: 450.ms,
                curve: Curves.easeOutCubic,
              ),
    );
  }

  Widget _buildHeader() {
    final nama = ref.read(authRepositoryProvider).displayName.split(' ').first;
    final notifAktif = ref
        .watch(notificationSettingsProvider)
        .maybeWhen(data: (s) => s.reminderCatatAktif, orElse: () => false);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Halo, $nama 👋', style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Text(
                    'Semangat mengatur keuangan hari ini!',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                notifAktif
                    ? Icons.notifications_active
                    : Icons.notifications_off_outlined,
                color: notifAktif ? AppColors.primary : null,
              ),
              onPressed: () => notifAktif
                  ? context.push('/notifikasi')
                  : tawarkanNotif(context, ref, JenisReminder.catat),
            ),
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        ),
        const SizedBox(height: 10),
        const HeaderLine(),
      ],
    );
  }

  Widget _buildSaldoCard(double saldo) {
    const saldoStyle = TextStyle(
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.w800,
      shadows: [
        Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 6),
      ],
    );

    return Container(
          width: double.infinity,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Saldo Saat Ini',
                    style: TextStyle(
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
                  IconButton(
                    icon: AnimatedSwitcher(
                      duration: 200.ms,
                      child: Icon(
                        _saldoVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        key: ValueKey(_saldoVisible),
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _saldoVisible = !_saldoVisible;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: 250.ms,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  // ignore: use_null_aware_elements
                  children: [...previous, if (current != null) current],
                ),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: .94, end: 1).animate(anim),
                    alignment: Alignment.centerLeft,
                    child: child,
                  ),
                ),
                child: _saldoVisible
                    ? AnimatedCount(
                        key: const ValueKey('on'),
                        value: saldo,
                        format: _rupiah,
                        style: saldoStyle,
                      )
                    : const Text(
                        'Rp••••••••',
                        key: ValueKey('off'),
                        style: saldoStyle,
                      ),
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          delay: 3.seconds,
          duration: 1600.ms,
          color: Colors.white.withValues(alpha: .28),
        );
  }

  Widget _buildRekeningRow(List<WalletBalance> walletBalances) {
    if (walletBalances.isEmpty) {
      return Text('Belum ada wallet.', style: AppTextStyles.caption);
    }

    return Row(
      children: walletBalances.map((wb) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppCard(
              borderColor: Colors.black,
              borderWidth: 0.5,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: accentTeal.withValues(alpha: 0.15),
                    child: Icon(
                      wb.wallet.type.icon,
                      color: accentTeal,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(wb.wallet.name, style: AppTextStyles.caption),
                        Text(
                          _rupiah(wb.balance),
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRingkasanRow(double pemasukan, double pengeluaran) {
    final items = [
      {
        'label': 'Pemasukan',
        'nominal': pemasukan,
        'naik': true,
        'icon': Icons.arrow_downward,
      },
      {
        'label': 'Pengeluaran',
        'nominal': pengeluaran,
        'naik': false,
        'icon': Icons.arrow_upward,
      },
    ];

    return Row(
      children: items.map((r) {
        final naik = r['naik'] as bool;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppCard(
              borderColor: Colors.black,
              borderWidth: 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    r['icon'] as IconData,
                    color: naik ? context.pal.success : context.pal.error,
                  ),
                  const SizedBox(height: 8),
                  Text(r['label'] as String, style: AppTextStyles.caption),
                  Text(
                    _rupiah(r['nominal'] as double),
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFinancialTools() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _financialTools.map((t) {
        return Column(
          children: [
            PressableScale(
              scale: .92,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.selectionClick();
                  final label = t['label'] as String;
                  if (label == 'Target') {
                    context.push('/target');
                  } else if (label == 'Tagihan') {
                    context.push('/tagihan');
                  } else if (label == 'Budget/Limit') {
                    context.push('/budget');
                  } else if (label == 'Laporan') {
                    context.push('/laporan');
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(color: context.pal.outline, width: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    t['icon'] as IconData,
                    color: const Color(0xFFB5651D),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(t['label'] as String, style: AppTextStyles.caption),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStreakBanner(int streak) {
    final String judul;
    final String pesan;

    if (streak <= 0) {
      judul = 'Mulai streak-mu! 🔥';
      pesan = 'Catat transaksi hari ini untuk memulai streak.';
    } else if (streak <= 2) {
      judul = 'Lanjutkan terus! 💪';
      pesan = 'Konsisten mencatat beberapa hari terakhir. Jangan putus ya!';
    } else {
      judul = 'Streak keren! 🔥';
      pesan = 'Kamu sudah mencatat selama $streak hari berturut-turut!';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning,
        border: Border.all(color: context.pal.outline, width: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF2B1B10),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pesan,
            style: AppTextStyles.body.copyWith(color: const Color(0xFF2B1B10)),
          ),
        ],
      ),
    );
  }
}
