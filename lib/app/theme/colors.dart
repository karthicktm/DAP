import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Modern Purple Gradient
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF7C3AED);

  // Secondary Colors - Modern Teal
  static const Color secondary = Color(0xFF14B8A6);
  static const Color secondaryLight = Color(0xFF5EEAD4);
  static const Color secondaryDark = Color(0xFF0D9488);

  // Background Colors - Dark Theme
  static const Color background = Color(0xFF0F0F23);  // Deep Space Blue
  static const Color surface = Color(0xFF1A1B3A);     // Midnight Purple
  static const Color surfaceVariant = Color(0xFF252641); // Lighter Surface

  // Background Colors - Light Theme
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textDisabled = Color(0xFF64748B);

  // Accent Colors
  static const Color accent = Color(0xFFEC4899);      // Hot Pink
  static const Color accentLight = Color(0xFFF9A8D4);  // Light Pink
  static const Color success = Color(0xFF10B981);      // Emerald
  static const Color warning = Color(0xFFF59E0B);      // Amber
  static const Color error = Color(0xFFEF4444);        // Red

  // Glass Effect Colors
  static const Color glassBackground = Color(0x30FFFFFF);
  static const Color glassBorder = Color(0x20FFFFFF);
  static const Color glassShadow = Color(0x10000000);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF8B5CF6),
    Color(0xFF7C3AED),
    Color(0xFF6D28D9),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF14B8A6),
    Color(0xFF0D9488),
    Color(0xFF0F766E),
  ];

  static const List<Color> backgroundGradient = [
    Color(0xFF0F0F23),
    Color(0xFF1A1B3A),
    Color(0xFF252641),
  ];

  static const List<Color> buttonGradient = [
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  // Audio Visualization Colors
  static const Color audioWavePrimary = Color(0xFF8B5CF6);
  static const Color audioWaveSecondary = Color(0xFF14B8A6);
  static const Color audioWaveAccent = Color(0xFFEC4899);

  // Status Colors
  static const Color online = Color(0xFF10B981);      // Green
  static const Color offline = Color(0xFF6B7280);     // Gray
  static const Color live = Color(0xFFEF4444);        // Red
  static const BufferingColor = Color(0xFFF59E0B);    // Amber

  // Social/Chat Colors
  static const Color chatBubble = Color(0xFF252641);
  static const Color chatBubbleOwn = Color(0xFF8B5CF6);
  static const Color giftColor = Color(0xFFEC4899);

  // Rating/Badge Colors
  static const Color gold = Color(0xFFF59E0B);
  static const Color silver = Color(0xFF9CA3AF);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color diamond = Color(0xFF60A5FA);

  // Transparent Colors
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  static Color surfaceWithOpacity(double opacity) => surface.withOpacity(opacity);
  static Color backgroundWithOpacity(double opacity) => background.withOpacity(opacity);
}