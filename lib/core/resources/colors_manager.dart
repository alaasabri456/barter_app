import 'package:flutter/material.dart';

class ColorsManager {
  // Primary Colors - Vibrant Purple (from logo bottom)
  static const Color primaryLight = Color(0xFFA855F7); // Purple 500
  static const Color primaryDark = Color(0xFF9333EA); // Purple 600
  static const Color primaryVariant = Color(0xFF7E22CE); // Purple 700

  // Secondary Colors - Orange/Amber (from logo top)
  static const Color secondaryLight = Color(0xFFF97316); // Orange 500
  static const Color secondaryDark = Color(0xFFEA580C); // Orange 600

  // Background Colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Accent Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);

  // Neutral Colors - Slate palette
  static const Color grey50 = Color(0xFFF8FAFC);
  static const Color grey100 = Color(0xFFF1F5F9);
  static const Color grey200 = Color(0xFFE2E8F0);
  static const Color grey300 = Color(0xFFCBD5E1);
  static const Color grey400 = Color(0xFF94A3B8);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey600 = Color(0xFF475569);
  static const Color grey700 = Color(0xFF334155);
  static const Color grey800 = Color(0xFF1E293B);
  static const Color grey900 = Color(0xFF0F172A);

  // Card Colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B);

  // Border Colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x4D000000);

  // Status Colors for Products - More vibrant
  static const Color available = Color(0xFF10B981); // Emerald
  static const Color traded = Color(0xFF3B82F6); // Blue
  static const Color unavailable = Color(0xFF94A3B8); // Slate

  // Category Colors - Vibrant and distinct
  static const Color electronics = Color(0xFF3B82F6); // Blue
  static const Color clothing = Color(0xFFA855F7); // Purple
  static const Color books = Color(0xFFF59E0B); // Amber
  static const Color sports = Color(0xFF10B981); // Emerald
  static const Color home = Color(0xFFEF4444); // Red
  static const Color others = Color(0xFF64748B); // Slate

  // Gradient Colors
  static const Color gradientStart = Color(0xFFFACC15); // Yellow
  static const Color gradientMiddle = Color(0xFFF97316); // Orange
  static const Color gradientEnd = Color(0xFFA855F7); // Purple

  // Secondary Gradient
  static const Color secondaryGradientStart = Color(0xFFA855F7); // Purple
  static const Color secondaryGradientEnd = Color(0xFFEC4899); // Pink

  // Premium Colors
  static const Color premiumGold = Color(0xFFFFB800);
  static const Color premiumOrange = Color(0xFFFF8C00);
  static const Color premiumDeep = Color(0xFFE65100);

  // Glassmorphism
  static const Color glassLight = Color(0xCCFFFFFF); // 80% white
  static const Color glassDark = Color(0xCC1E293B); // 80% dark slate

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientMiddle, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryGradientStart, secondaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFFE2E8F0), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  // Category Gradients
  static const LinearGradient electronicsGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient clothingGradient = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient booksGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sportsGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient homeGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient othersGradient = LinearGradient(
    colors: [Color(0xFF64748B), Color(0xFF475569)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
