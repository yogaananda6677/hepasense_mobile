import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Final HepaSense mint/teal palette (Phase 15C).
  static const Color primary = Color(0xFF00685D);
  static const Color primaryDark = Color(0xFF00574E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFDDF3EF);
  static const Color onPrimaryContainer = Color(0xFF00574E);
  static const Color primarySoft = Color(0xFFDDF3EF);
  static const Color accent = Color(0xFF2D8C83);

  // Secondary brand colors
  static const Color secondary = accent;
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = primarySoft;
  static const Color onSecondaryContainer = primaryDark;

  // Tertiary
  static const Color tertiary = Color(0xFF2E7D32);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFE8F5E9);
  static const Color onTertiaryContainer = Color(0xFF2E7D32);

  // Error
  static const Color error = Color(0xFFB42318);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFDEBEC);
  static const Color onErrorContainer = Color(0xFFB42318);

  // Surface
  static const Color background = Color(0xFFF7FAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1D2926);
  static const Color surfaceContainer = Color(0xFFF0F6F4);
  static const Color surfaceContainerLow = background;
  static const Color onSurfaceVariant = Color(0xFF61706C);
  static const Color infoSurface = Color(0xFFE9F6FD);

  // Outline
  static const Color outline = Color(0xFF9AABA6);
  static const Color outlineVariant = Color(0xFFDCE8E5);
  static const Color borderSoft = Color(0xFFDCE8E5);
  static const Color cardShadow = Color(0x0F1D2926);
  static const Color divider = borderSoft;
  static const Color disabled = Color(0xFF9AA6A2);
  static const Color navigationBackground = Color(0xFFF5FBFA);
  static const Color navigationActive = Color(0xFFCFE9E5);

  // Custom Stitch Gradient & Metric Tokens
  static const Color heroGradientStart = Color(0xFF00695C);
  static const Color heroGradientEnd = Color(0xFF26A69A);
  static const Color metricCardBg = Color(0xFFF0F7F6);
  static const Color metricBorder = Color(0xFFD9E5E4);

  // Status colors (not sole communicator — always pair with text/icon)
  static const Color statusHealthySurface = Color(0xFFE8F5E9);
  static const Color statusHealthy = Color(0xFF2E7D32);
  static const Color statusWarningSurface = Color(0xFFFFF4D6);
  static const Color statusWarning = Color(0xFF9A6700);
  static const Color statusHighRiskSurface = Color(0xFFFDEBEC);
  static const Color statusHighRisk = Color(0xFFB42318);
  static const Color statusInvalidSurface = Color(0xFFEEF2F4);
  static const Color statusInvalid = Color(0xFF5E6A71);
}

