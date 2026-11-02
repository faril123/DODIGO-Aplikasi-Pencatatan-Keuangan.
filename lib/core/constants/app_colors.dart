import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary (amber)
  static const Color primary = Color(0xFFFFB400);
  static const Color primaryDark = Color(
    0xFF8A5A00,
  ); // ikon & teks aksen di atas krem
  static const Color primaryLight = Color(0xFFFBEFD3); // latar lingkaran ikon
  static const Color onPrimary = Colors.white;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB400), Color(0xFFFFCB47)],
  );

  // Status
  static const Color success = Color(0xFF1E7B3C);
  static const Color warning = Color(0xFFFFB400);
  static const Color error = Color(0xFFB3261E);

  // Background & card
  static const Color background = Color(0xFFFFF8F0);
  static const Color card = Color(0xFFFFFDF5);

  // Text
  static const Color textPrimary = Color(0xFF2B1B10);
  static const Color textSecondary = Color(0xFF7A6A5A);

  // Border
  static const Color border = Color(0xFFEADFCB);
  static const Color outlineStrong = Color(0xFF5A3E0B);
}
