import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';

/// Garis dekoratif di bawah header: titik amber + garis gradient yang
/// "tergambar" dari kiri dan memudar ke kanan.
class HeaderLine extends StatelessWidget {
  const HeaderLine({super.key, this.delay = const Duration(milliseconds: 300)});

  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child:
              Container(
                height: 1.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ).animate().scaleX(
                begin: 0,
                end: 1,
                alignment: Alignment.centerLeft,
                delay: delay,
                duration: 700.ms,
                curve: Curves.easeOutCubic,
              ),
        ),
      ],
    );
  }
}
