import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/theme/app_palette.dart';

import '../../shared/widgets/app_background.dart';
import '../../shared/models/wallet_model.dart';
import '../../shared/widgets/info_bubble.dart';
import '../../shared/widgets/primary_button.dart';
import '../auth/auth_provider.dart';
import 'wallet_setup_form.dart';
export '../wallet/wallet_provider.dart';

class WalletSetupPage extends ConsumerStatefulWidget {
  const WalletSetupPage({super.key});

  @override
  ConsumerState<WalletSetupPage> createState() => _WalletSetupPageState();
}

class _WalletSetupPageState extends ConsumerState<WalletSetupPage> {
  final List<WalletModel> _walletsAdded = [];
  bool _saving = false;

  Future<void> _selesai() async {
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).completeOnboarding();
      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        showInfoBubble(
          context,
          success: false,
          messages: ['Gagal menyelesaikan: $e'],
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final pertama = _walletsAdded.isEmpty;

    return ColoredBox(
      color: pal.background,
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _saving ? null : _selesai,
                          child: const Text('Lewati dulu'),
                        ),
                      ),
                      Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: pal.primaryLight,
                              border: Border.all(
                                color: pal.outline,
                                width: 0.5,
                              ),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 30,
                              color: pal.primaryDark,
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(
                            begin: 0,
                            end: -6,
                            duration: 1400.ms,
                            curve: Curves.easeInOut,
                          ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: 300.ms,
                        transitionBuilder: (c, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, .2),
                              end: Offset.zero,
                            ).animate(a),
                            child: c,
                          ),
                        ),
                        child: Align(
                          key: ValueKey(pertama),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            pertama
                                ? 'Buat Wallet Pertama Kamu! 🎉'
                                : 'Tambah Wallet Lagi?',
                            style: AppTextStyles.heading,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pilih jenis wallet dan masukkan saldo awalmu untuk mulai mengatur keuangan.',
                        style: AppTextStyles.body.copyWith(
                          color: pal.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_walletsAdded.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _walletsAdded
                              .map(
                                (w) =>
                                    Chip(
                                          avatar: Icon(
                                            w.type.icon,
                                            size: 16,
                                            color: pal.primaryDark,
                                          ),
                                          label: Text(w.name),
                                          backgroundColor: pal.primaryLight,
                                          side: BorderSide(
                                            color: AppColors.primary,
                                            width: 0.8,
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(duration: 200.ms)
                                        .scale(
                                          begin: const Offset(.6, .6),
                                          duration: 350.ms,
                                          curve: Curves.easeOutBack,
                                        ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Expanded(
                        child:
                            SingleChildScrollView(
                                  child: WalletSetupForm(
                                    onSaved: (wallet) {
                                      HapticFeedback.mediumImpact();
                                      setState(() => _walletsAdded.add(wallet));
                                    },
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 350.ms)
                                .slideY(
                                  begin: .05,
                                  end: 0,
                                  duration: 400.ms,
                                  curve: Curves.easeOutCubic,
                                ),
                      ),
                      if (_walletsAdded.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        PrimaryButton(
                              text: 'Selesai, ke Dashboard →',
                              loading: _saving,
                              onPressed: _selesai,
                            )
                            .animate()
                            .fadeIn(duration: 250.ms)
                            .slideY(
                              begin: .4,
                              end: 0,
                              duration: 350.ms,
                              curve: Curves.easeOutCubic,
                            ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
