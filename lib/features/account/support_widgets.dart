import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/header_line.dart';
import '../../shared/widgets/pressable_scale.dart';

class SupportScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SupportScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;

    return ColoredBox(
      color: pal.background,
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
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
                              color: pal.card,
                              border: Border.all(
                                color: pal.outline,
                                width: 0.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
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
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: children
                        .animate(interval: 60.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(
                          begin: .08,
                          end: 0,
                          duration: 420.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SupportCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const SupportCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.pal.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.pal.outline, width: 0.5),
      ),
      child: child,
    );
  }
}

/// Kotak ikon kecil (sama gaya dengan menu di halaman Akun).
class SupportIconBox extends StatelessWidget {
  final IconData icon;

  const SupportIconBox(this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.pal.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: context.pal.primaryDark),
    );
  }
}

/// Banner amber dengan ikon, judul, dan subjudul.
class SupportBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SupportBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    const tinta = Color(0xFF2B1B10);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.pal.outline, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.55),
            ),
            child: Icon(icon, color: tinta, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 16,
                    color: tinta,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: tinta.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const emailDukungan = 'farilrahman27@gmail.com';
