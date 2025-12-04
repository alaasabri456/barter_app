import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/resources/colors_manager.dart';
import '../core/resources/text_styles_manager.dart';

class ThemeManager {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: ColorsManager.primaryLight,
    scaffoldBackgroundColor: ColorsManager.backgroundLight,

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: ColorsManager.surfaceLight,
      foregroundColor: ColorsManager.textPrimaryLight,
      elevation: 0,
      titleTextStyle: TextStylesManager.appBarTitleLight,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: ColorsManager.cardLight,
      elevation: 3,
      shadowColor: ColorsManager.primaryLight.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Bottom Navigation Bar Theme
    // bottomNavigationBarTheme: BottomNavigationBarThemeData(
    //   elevation: 0,
    //   backgroundColor: Colors.white,
    //   selectedItemColor: Colors.blue,
    //   unselectedItemColor: Colors.grey,
    // ),
    // floatingActionButtonTheme: const FloatingActionButtonThemeData(
    //   backgroundColor: Colors.orange,
    //   foregroundColor: Colors.white,
    //   shape: CircleBorder(),
    // ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsManager.primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: ColorsManager.primaryLight.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStylesManager.buttonLarge,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorsManager.primaryLight,
        side: BorderSide(color: ColorsManager.primaryLight, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStylesManager.buttonLarge,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorsManager.primaryLight,
        textStyle: TextStylesManager.buttonMedium,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorsManager.grey50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ColorsManager.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ColorsManager.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ColorsManager.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ColorsManager.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ColorsManager.error, width: 2),
      ),
      hintStyle: TextStylesManager.bodyMediumLight.copyWith(
        color: ColorsManager.grey500,
      ),
      labelStyle: TextStylesManager.labelLight,
      errorStyle: TextStylesManager.error,
    ),

    // Text Theme
    textTheme: TextTheme(
      headlineLarge: TextStylesManager.h1Light,
      headlineMedium: TextStylesManager.h2Light,
      headlineSmall: TextStylesManager.h3Light,
      titleLarge: TextStylesManager.h4Light,
      bodyLarge: TextStylesManager.bodyLargeLight,
      bodyMedium: TextStylesManager.bodyMediumLight,
      bodySmall: TextStylesManager.bodySmallLight,
      labelLarge: TextStylesManager.labelLight,
      labelMedium: TextStylesManager.captionLight,
    ),

    // Color Scheme
    colorScheme: ColorScheme.light(
      primary: ColorsManager.primaryLight,
      secondary: ColorsManager.secondaryLight,
      surface: ColorsManager.surfaceLight,
      background: ColorsManager.backgroundLight,
      error: ColorsManager.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: ColorsManager.textPrimaryLight,
      onBackground: ColorsManager.textPrimaryLight,
      onError: Colors.white,
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: ColorsManager.primaryDark,
    scaffoldBackgroundColor: ColorsManager.backgroundDark,

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: ColorsManager.surfaceDark,
      foregroundColor: ColorsManager.textPrimaryDark,
      elevation: 0,
      titleTextStyle: TextStylesManager.appBarTitleDark,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: ColorsManager.cardDark,
      elevation: 3,
      shadowColor: ColorsManager.primaryDark.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: ColorsManager.surfaceDark,
      selectedItemColor: ColorsManager.primaryDark,
      unselectedItemColor: ColorsManager.grey400,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStylesManager.tabSelected.copyWith(
        color: ColorsManager.primaryDark,
      ),
      unselectedLabelStyle: TextStylesManager.tabUnselected.copyWith(
        color: ColorsManager.grey400,
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorsManager.primaryDark,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: ColorsManager.primaryDark.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStylesManager.buttonLarge,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorsManager.primaryDark,
        side: BorderSide(color: ColorsManager.primaryDark, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStylesManager.buttonLarge,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorsManager.primaryDark,
        textStyle: TextStylesManager.buttonMedium,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorsManager.grey800,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ColorsManager.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ColorsManager.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ColorsManager.primaryDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ColorsManager.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ColorsManager.error, width: 2),
      ),
      hintStyle: TextStylesManager.bodyMediumDark.copyWith(
        color: ColorsManager.grey400,
      ),
      labelStyle: TextStylesManager.labelDark,
      errorStyle: TextStylesManager.error,
    ),

    // Text Theme
    textTheme: TextTheme(
      headlineLarge: TextStylesManager.h1Dark,
      headlineMedium: TextStylesManager.h2Dark,
      headlineSmall: TextStylesManager.h3Dark,
      titleLarge: TextStylesManager.h4Dark,
      bodyLarge: TextStylesManager.bodyLargeDark,
      bodyMedium: TextStylesManager.bodyMediumDark,
      bodySmall: TextStylesManager.bodySmallDark,
      labelLarge: TextStylesManager.labelDark,
      labelMedium: TextStylesManager.captionDark,
    ),

    // Color Scheme
    colorScheme: ColorScheme.dark(
      primary: ColorsManager.primaryDark,
      secondary: ColorsManager.secondaryDark,
      surface: ColorsManager.surfaceDark,
      background: ColorsManager.backgroundDark,
      error: ColorsManager.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: ColorsManager.textPrimaryDark,
      onBackground: ColorsManager.textPrimaryDark,
      onError: Colors.white,
    ),
  );
}
