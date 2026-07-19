import 'package:flutter/material.dart';

/// Custom color tokens used across Lumio.
/// Access anywhere with: Theme.of(context).extension<AppColors>()!
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface; // AppBar / bottom bar background
  final Color card; // AI bubble / card background
  final Color primary; // Main purple (buttons, user bubble)
  final Color accent; // Neon green (slide number chip)
  final Color accentBg; // Background behind accent chip
  final Color accentBorder; // Border behind accent chip
  final Color textPurple; // Text on primary-colored bubbles
  final Color textPrimary; // Main body text
  final Color textSecondary; // Hints, subtitles, grey text
  final Color inputFill; // Text field / language pill background
  final Color inputBorder; // Text field / language pill border
  final Color danger; // Mic active / errors / high exam importance
  final Color warning; // Mid exam importance
  final Color border; // Generic card border

  const AppColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.primary,
    required this.accent,
    required this.accentBg,
    required this.accentBorder,
    required this.textPurple,
    required this.textPrimary,
    required this.textSecondary,
    required this.inputFill,
    required this.inputBorder,
    required this.danger,
    required this.warning,
    required this.border,
  });

  /// Your existing dark theme — colors kept exactly as they were.
  static const dark = AppColors(
    background: Color(0xFF0D0D18),
    surface: Color(0xFF131324),
    card: Color(0xFF1A1A2E),
    primary: Color(0xFF534AB7),
    accent: Color(0xFF5DCAA5),
    accentBg: Color(0xFF162525),
    accentBorder: Color(0xFF1D453B),
    textPurple: Color(0xFFCECBF6),
    textPrimary: Colors.white,
    textSecondary: Colors.grey,
    inputFill: Color(0xFF1E1E2E),
    inputBorder: Color(0xFF3C3489),
    danger: Color(0xFFE24B4A),
    warning: Color(0xFFEF9F27),
    border: Color(0xFF22223B),
  );

  /// New light theme — same purple/violet family as the dark theme,
  /// adapted for a white/soft-lavender background (matches the
  /// "Welcome Back" / Home screen style you liked).
  static const light = AppColors(
    background: Color(0xFFF6F5FC), // soft lavender-white
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF6C5CE7), // vivid violet, matches Log In button
    accent: Color(0xFF1FA37C), // deeper green, readable on white
    accentBg: Color(0xFFE6F7F1),
    accentBorder: Color(0xFFBEE9D9),
    textPurple: Color(0xFFFFFFFF), // text on the primary user bubble
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF6B6B80),
    inputFill: Color(0xFFF0EEFB),
    inputBorder: Color(0xFFD9D3F5),
    danger: Color(0xFFE53E3E),
    warning: Color(0xFFDD8A1F),
    border: Color(0xFFE7E3F7),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? primary,
    Color? accent,
    Color? accentBg,
    Color? accentBorder,
    Color? textPurple,
    Color? textPrimary,
    Color? textSecondary,
    Color? inputFill,
    Color? inputBorder,
    Color? danger,
    Color? warning,
    Color? border,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      accentBg: accentBg ?? this.accentBg,
      accentBorder: accentBorder ?? this.accentBorder,
      textPurple: textPurple ?? this.textPurple,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      inputFill: inputFill ?? this.inputFill,
      inputBorder: inputBorder ?? this.inputBorder,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      border: border ?? this.border,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentBg: Color.lerp(accentBg, other.accentBg, t)!,
      accentBorder: Color.lerp(accentBorder, other.accentBorder, t)!,
      textPurple: Color.lerp(textPurple, other.textPurple, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}