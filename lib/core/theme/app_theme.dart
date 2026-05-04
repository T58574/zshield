import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color background = Color(0xFF000000); // Base Layer
  static const Color surface = Color(0xFF121414);
  static const Color primary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFe3e2e2);
  static const Color onSurfaceVariant = Color(0xFFc4c7c8);
  static const Color error = Color(0xFFffb4ab);
  
  // Custom tokens
  static const Color surfaceContainerLowest = Color(0xFF0d0e0f);
  static const Color outline = Color(0xFF8e9192);
  
  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    
    // Space Grotesk for display and headlines
    final spaceGrotesk = GoogleFonts.spaceGroteskTextTheme(baseTextTheme);
    // Manrope for body and labels
    final manrope = GoogleFonts.manropeTextTheme(baseTextTheme);
    
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        onSurface: onSurface,
        error: error,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: spaceGrotesk.displayLarge?.copyWith(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -0.02 * 48,
          color: primary,
        ),
        headlineMedium: spaceGrotesk.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          height: 1.2,
          color: primary,
        ),
        titleSmall: manrope.titleSmall?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: primary,
        ),
        bodyMedium: manrope.bodyMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: onSurface,
        ),
        labelSmall: manrope.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.0,
          letterSpacing: 1.1, // 0.1em approx
          color: onSurfaceVariant,
        ),
        bodySmall: spaceGrotesk.bodySmall?.copyWith( // mapped to mono-data
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.0,
          color: primary.withOpacity(0.6),
        ),
      ),
    );
  }
}
