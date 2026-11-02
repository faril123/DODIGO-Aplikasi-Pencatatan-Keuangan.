import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/theme/app_palette.dart';
import '../models/wallet_model.dart';
import 'pressable_scale.dart';

/// Warna khas tiap jenis wallet (dipakai juga di halaman Kelola Wallet).
Color warnaJenisWallet(WalletType t) => switch (t) {
  WalletType.cash => const Color(0xFF43A047),
  WalletType.bank => const Color(0xFF1E88E5),
  WalletType.ewallet => const Color(0xFF8E24AA),
};

class WalletTypePicker extends StatelessWidget {
  final WalletType selected;
  final ValueChanged<WalletType> onChanged;

  const WalletTypePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final jenis = WalletType.values;

    return Row(
      children: [
        for (final (i, type) in jenis.indexed)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == jenis.length - 1 ? 0 : 8),
              child: PressableScale(
                scale: .95,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(type);
                  },
                  child: AnimatedContainer(
                    duration: 220.ms,
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected == type ? pal.primaryLight : pal.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected == type
                            ? AppColors.primary
                            : pal.outline,
                        width: selected == type ? 1.6 : 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        AnimatedScale(
                          scale: selected == type ? 1.2 : 1,
                          duration: 280.ms,
                          curve: Curves.easeOutBack,
                          child: Icon(
                            type.icon,
                            color: selected == type
                                ? pal.primaryDark
                                : pal.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedDefaultTextStyle(
                          duration: 200.ms,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: selected == type
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: selected == type ? pal.primaryDark : null,
                          ),
                          child: Text(type.label),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
