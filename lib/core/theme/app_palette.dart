import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color card;
  final Color field; // isi input & kotak info (dulu Colors.white)
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color outline; // border kartu (dulu Colors.black)
  final Color primaryLight;
  final Color primaryDark;
  final Color success;
  final Color error;

  const AppPalette({
    required this.background,
    required this.card,
    required this.field,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.outline,
    required this.primaryLight,
    required this.primaryDark,
    required this.success,
    required this.error,
  });

  static const light = AppPalette(
    background: AppColors.background,
    card: AppColors.card,
    field: Colors.white,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    border: AppColors.border,
    outline: Colors.black,
    primaryLight: AppColors.primaryLight,
    primaryDark: AppColors.primaryDark,
    success: AppColors.success,
    error: AppColors.error,
  );

  static const dark = AppPalette(
    background: Color(0xFF1A1410),
    card: Color(0xFF241C15),
    field: Color(0xFF2E241B),
    textPrimary: Color(0xFFF5ECDD),
    textSecondary: Color(0xFFB5A590),
    border: Color(0xFF3A2F24),
    outline: Color(0xFF5C4A36),
    primaryLight: Color(0xFF3A2C12),
    primaryDark: Color(0xFFFFC857),
    success: Color(0xFF4CAF6A),
    error: Color(0xFFFF6B60),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? card,
    Color? field,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? outline,
    Color? primaryLight,
    Color? primaryDark,
    Color? success,
    Color? error,
  }) {
    return AppPalette(
      background: background ?? this.background,
      card: card ?? this.card,
      field: field ?? this.field,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      outline: outline ?? this.outline,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      success: success ?? this.success,
      error: error ?? this.error,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      card: l(card, other.card),
      field: l(field, other.field),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      border: l(border, other.border),
      outline: l(outline, other.outline),
      primaryLight: l(primaryLight, other.primaryLight),
      primaryDark: l(primaryDark, other.primaryDark),
      success: l(success, other.success),
      error: l(error, other.error),
    );
  }
}

extension AppPaletteX on BuildContext {
  /// Pemakaian: context.pal.card, context.pal.outline, dst.
  AppPalette get pal =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
