import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/animated_count.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/header_line.dart';
import '../../shared/widgets/pressable_scale.dart';
import '../auth/auth_provider.dart';
import '../transaction/transaction_provider.dart';
import '../wallet/wallet_provider.dart';
import 'bantuan_page.dart';
import 'privasi_page.dart';
import 'tentang_page.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  void _buka(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _logout() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Kamu harus login lagi untuk memakai DODIGI.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Keluar', style: TextStyle(color: ctx.pal.error)),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    await ref.read(authRepositoryProvider).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = ref.read(authRepositoryProvider);
    final nama = authRepo.displayName;
    final email = authRepo.currentUser?.email ?? '-';
    final meta = authRepo.currentUser?.userMetadata;
    final foto = (meta?['avatar_url'] ?? meta?['picture']) as String?;

    final versi = ref.watch(versiAplikasiProvider).valueOrNull;
    final modeGelap = ref.watch(themeModeProvider) == ThemeMode.dark;

    final jumlahTransaksi =
        ref.watch(transactionsProvider).valueOrNull?.length ?? 0;
    final streak = ref.watch(streakProvider);
    final jumlahWallet = ref.watch(walletsProvider).valueOrNull?.length ?? 0;

    return ColoredBox(
      color: context.pal.background,
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Akun Saya'),
            centerTitle: true,
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children:
                <Widget>[
                      _buildHeader(
                        nama,
                        email,
                        foto,
                        jumlahTransaksi,
                        streak,
                        jumlahWallet,
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        label: 'PENGATURAN',
                        children: [
                          _MenuTile(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Dompet & Rekening',
                            onTap: () => context.push('/wallets'),
                          ),
                          const _MenuTile(
                            icon: Icons.lock_outline,
                            title: 'Keamanan',
                            subtitle: 'PIN & Biometrik',
                            comingSoon: true,
                          ),
                          _MenuTile(
                            icon: Icons.notifications_none,
                            title: 'Notifikasi',
                            onTap: () => context.push('/notifikasi'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        label: 'PREFERENSI',
                        children: [
                          _MenuTile(
                            icon: modeGelap
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                            title: 'Mode Gelap',
                            trailing: Switch(
                              value: modeGelap,
                              thumbColor: WidgetStateProperty.all(Colors.white),
                              trackColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                    ? AppColors.primary
                                    : context.pal.border,
                              ),
                              trackOutlineColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              onChanged: (v) {
                                HapticFeedback.selectionClick();
                                ref
                                    .read(themeModeProvider.notifier)
                                    .set(v ? ThemeMode.dark : ThemeMode.light);
                              },
                            ),
                          ),
                          const _MenuTile(
                            icon: Icons.language,
                            title: 'Bahasa',
                            trailingText: 'Indonesia',
                            comingSoon: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        label: 'DUKUNGAN',
                        children: [
                          _MenuTile(
                            icon: Icons.help_outline,
                            title: 'Bantuan & FAQ',
                            onTap: () => _buka(const BantuanPage()),
                          ),
                          _MenuTile(
                            icon: Icons.shield_outlined,
                            title: 'Kebijakan Privasi',
                            onTap: () => _buka(const PrivasiPage()),
                          ),
                          _MenuTile(
                            icon: Icons.info_outline,
                            title: 'Tentang DODIGI',
                            trailingText: versi == null ? null : 'v$versi',
                            onTap: () => _buka(const TentangPage()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildLogoutButton(),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'DODIGI${versi == null ? '' : ' • v$versi'}',
                          style: AppTextStyles.caption,
                        ),
                      ),
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

  // ---------------------------------------------------------------------------
  // Header profil
  // ---------------------------------------------------------------------------

  Widget _inisial(String nama) {
    return Container(
      color: context.pal.primaryLight,
      alignment: Alignment.center,
      child: Text(
        nama.isNotEmpty ? nama[0].toUpperCase() : '?',
        style: AppTextStyles.heading.copyWith(color: context.pal.primaryDark),
      ),
    );
  }

  Widget _buildAvatar(String nama, String? foto) {
    return SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cincin gradient yang berputar pelan.
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      AppColors.primary,
                      Color(0xFFFFE08A),
                      AppColors.primary,
                    ],
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 6.seconds),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.pal.background,
                ),
              ),
              ClipOval(
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: foto != null && foto.isNotEmpty
                      ? Image.network(
                          foto,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _inisial(nama),
                        )
                      : _inisial(nama),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .scaleXY(begin: .6, end: 1, duration: 700.ms, curve: Curves.elasticOut);
  }

  Widget _buildHeader(
    String nama,
    String email,
    String? foto,
    int jumlahTransaksi,
    int streak,
    int jumlahWallet,
  ) {
    return Column(
      children: [
        _buildAvatar(nama, foto),
        const SizedBox(height: 12),
        Text(nama, style: AppTextStyles.title),
        const SizedBox(height: 2),
        Text(email, style: AppTextStyles.caption),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatPill(
                icon: Icons.receipt_long_outlined,
                value: jumlahTransaksi,
                label: 'Transaksi',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatPill(
                icon: Icons.local_fire_department_outlined,
                value: streak,
                label: 'Hari streak',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatPill(
                icon: Icons.account_balance_wallet_outlined,
                value: jumlahWallet,
                label: 'Wallet',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    final merah = context.pal.error;
    return PressableScale(
      scale: .97,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          _logout();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: merah.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: merah, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: merah, size: 20),
              const SizedBox(width: 8),
              Text(
                'Keluar',
                style: AppTextStyles.body.copyWith(
                  color: merah,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Komponen
// =============================================================================

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.pal.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.pal.outline, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: context.pal.primaryDark),
          const SizedBox(height: 6),
          AnimatedCount(
            value: value.toDouble(),
            format: (v) => v.round().toString(),
            style: AppTextStyles.title,
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Sisipkan garis pemisah tipis antar menu.
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        spaced.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 52,
            color: context.pal.border,
          ),
        );
      }
      spaced.add(children[i]);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: context.pal.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.pal.outline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          ...spaced,
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingText,
    this.comingSoon = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? trailingText;
  final bool comingSoon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;

    final VoidCallback? aksi = comingSoon
        ? () {
            HapticFeedback.selectionClick();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text('$title segera hadir')));
          }
        : (onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                });

    return PressableScale(
      scale: .98,
      child: InkWell(
        onTap: aksi,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: pal.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedSwitcher(
                  duration: 250.ms,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    icon,
                    key: ValueKey(icon),
                    size: 20,
                    color: pal.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (trailingText != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(trailingText!, style: AppTextStyles.caption),
                ),
              if (comingSoon)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: pal.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Segera',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: pal.primaryDark,
                    ),
                  ),
                ),
              ?trailing,
              if (trailing == null && !comingSoon)
                Icon(Icons.chevron_right, color: pal.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
