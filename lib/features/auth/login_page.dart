import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../shared/widgets/bouncing_coins.dart';
import '../../shared/widgets/pressable_scale.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import 'auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _loading = false;

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (e) {
      debugPrint('Google login error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login dengan Google gagal. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(context),
            // Kartu naik menimpa bagian bawah hero.
            Transform.translate(
              offset: const Offset(0, -56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        _buildCard()
                            .animate()
                            .fadeIn(delay: 350.ms, duration: 500.ms)
                            .slideY(
                              begin: .25,
                              end: 0,
                              delay: 350.ms,
                              duration: 600.ms,
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: 28),
                        _buildFeatures(),
                        const SizedBox(height: 20),
                        Text(
                          'Dengan masuk, kamu menyetujui Kebijakan Privasi DODIGI.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ).animate().fadeIn(delay: 1100.ms, duration: 500.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    Widget item(IconData icon, String label) => Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outlineStrong, width: 1.2),
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );

    final items =
        <Widget>[
              item(Icons.edit_note_rounded, 'Catat\nTransaksi'),
              item(Icons.flag_rounded, 'Capai\nTarget'),
              item(Icons.insert_chart_rounded, 'Pantau\nLaporan'),
            ]
            .animate(interval: 120.ms, delay: 800.ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: .4, end: 0, curve: Curves.easeOutBack);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final w in items) Expanded(child: w)],
    );
  }

  Widget _buildHero(BuildContext context) {
    final logo =
        Image.asset(
              'assets/images/Logo.png',
              height: 300,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.account_balance_wallet_rounded,
                size: 150,
                color: Colors.white,
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .scaleXY(
              begin: .6,
              end: 1,
              duration: 800.ms,
              curve: Curves.elasticOut,
            );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: _circle(150, 0.14)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 1,
                  end: 1.15,
                  duration: 3.seconds,
                  curve: Curves.easeInOut,
                ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: _circle(100, 0.12)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 1.1,
                  end: .92,
                  duration: 2500.ms,
                  curve: Curves.easeInOut,
                ),
          ),
          // Lantai = tepi atas kartu (kartu naik 56px menimpa hero).
          const Positioned.fill(child: BouncingCoins(floorInset: 56)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 28,
              24,
              25,
            ),
            child: Center(
              child: logo
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                    begin: -6,
                    end: 6,
                    duration: 2200.ms,
                    curve: Curves.easeInOut,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outlineStrong, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            <Widget>[
                  Text(
                    'Selamat Datang! 👋',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.title.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mulai atur keuanganmu hari ini.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildGoogleButton(),
                ]
                .animate(interval: 90.ms, delay: 550.ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: .3, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return PressableScale(
          enabled: !_loading,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _loading ? null : _loginWithGoogle,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(
                  color: AppColors.outlineStrong,
                  width: 1.2,
                ),
                shape: const StadiumBorder(),
                textStyle: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              child: AnimatedSwitcher(
                duration: 200.ms,
                child: _loading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        key: const ValueKey('idle'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icons/Google.png',
                            width: 22,
                            height: 22,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata, size: 28),
                          ),
                          const SizedBox(width: 12),
                          const Text('Login dengan Google'),
                        ],
                      ),
              ),
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          delay: 2200.ms,
          duration: 1400.ms,
          color: AppColors.primary.withValues(alpha: .35),
        );
  }
}
