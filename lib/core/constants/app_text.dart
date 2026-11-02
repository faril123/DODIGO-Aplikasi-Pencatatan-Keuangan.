import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static final heading = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static final title = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static final body = GoogleFonts.poppins(fontSize: 14);

  static final caption = GoogleFonts.poppins(
    fontSize: 12,
    color: const Color(0xFF8C7C6A),
  );
}
