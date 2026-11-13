import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle displayLarge(Color color) => GoogleFonts.hankenGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle displayMedium(Color color) => GoogleFonts.hankenGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
        height: 1.25,
      );

  static TextStyle titleLarge(Color color) => GoogleFonts.hankenGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
        height: 1.3,
      );

  static TextStyle titleMedium(Color color) => GoogleFonts.hankenGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.1,
        height: 1.35,
      );

  static TextStyle bodyLarge(Color color) => GoogleFonts.hankenGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle bodyMedium(Color color) => GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle bodySmall(Color color) => GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.35,
      );

  static TextStyle labelLarge(Color color) => GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.1,
      );

  static TextStyle labelSmall(Color color) => GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.2,
      );
}
