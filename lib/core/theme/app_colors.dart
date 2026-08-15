import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF1B7A3D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFA7F5BA);
  static const Color onPrimaryContainer = Color(0xFF002109);

  // Secondary brand colors
  static const Color secondary = Color(0xFF4F6354);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD1E8D5);
  static const Color onSecondaryContainer = Color(0xFF0C1F13);

  // Tertiary
  static const Color tertiary = Color(0xFF3A656E);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFBDEAF5);
  static const Color onTertiaryContainer = Color(0xFF001F26);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // Surface
  static const Color surface = Color(0xFFF8FBF5);
  static const Color onSurface = Color(0xFF1A1C19);
  static const Color surfaceContainer = Color(0xFFECF0E6);
  static const Color onSurfaceVariant = Color(0xFF424940);

  // Outline
  static const Color outline = Color(0xFF727970);
  static const Color outlineVariant = Color(0xFFC2C9BE);

  // Status colors (not sole communicator — always pair with text/icon)
  static const Color statusHealthy = Color(0xFF1B7A3D);
  static const Color statusWarning = Color(0xFFE8A317);
  static const Color statusHighRisk = Color(0xFFBA1A1A);
  static const Color statusInvalid = Color(0xFF727970);
}
