import 'package:flutter/material.dart';

/// Paleta inspirada no dashboard da public-pool e na sua identidade
/// laranja/preto do Bitcoin.
class AppColors {
  static const bitcoin = Color(0xFFF7931A); // laranja Bitcoin
  static const bitcoinDark = Color(0xFFD97B0A);
  static const bg = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const surface2 = Color(0xFF262626);
  static const border = Color(0xFF333333);
  static const textPrimary = Color(0xFFF5F5F5);
  static const textMuted = Color(0xFF9A9A9A);
  static const green = Color(0xFF26A65B);
  static const red = Color(0xFFE0533D);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.bitcoin,
      secondary: AppColors.bitcoin,
      surface: AppColors.surface,
    ),
    cardColor: AppColors.surface,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
      fontFamily: 'monospace',
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
