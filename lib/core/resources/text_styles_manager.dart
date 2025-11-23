import 'package:barter/core/resources/colors_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class TextStylesManager {
  // Heading Styles
  static TextStyle get h1Light => TextStyle(
    fontSize: 32.sp,
    fontWeight: FontWeight.bold,
    color: ColorsManager.textPrimaryLight,
    height: 1.2,
  );

  static TextStyle get h1Dark => TextStyle(
    fontSize: 32.sp,
    fontWeight: FontWeight.bold,
    color: ColorsManager.textPrimaryDark,
    height: 1.2,
  );

  static TextStyle get h2Light => TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.bold,
    color: ColorsManager.textPrimaryLight,
    height: 1.3,
  );

  static TextStyle get h2Dark => TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.bold,
    color: ColorsManager.textPrimaryDark,
    height: 1.3,
  );

  static TextStyle get h3Light => TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.textPrimaryLight,
    height: 1.3,
  );

  static TextStyle get h3Dark => TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.textPrimaryDark,
    height: 1.3,
  );

  static TextStyle get h4Light => TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.textPrimaryLight,
    height: 1.4,
  );

  static TextStyle get h4Dark => TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.textPrimaryDark,
    height: 1.4,
  );

  // Body Text Styles
  static TextStyle get bodyLargeLight => TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.normal,
    color: ColorsManager.textPrimaryLight,
    height: 1.5,
  );

  static TextStyle get bodyLargeDark => TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.normal,
    color: ColorsManager.textPrimaryDark,
    height: 1.5,
  );

  static TextStyle get bodyMediumLight => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    color: ColorsManager.textPrimaryLight,
    height: 1.5,
  );

  static TextStyle get bodyMediumDark => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    color: ColorsManager.textPrimaryDark,
    height: 1.5,
  );

  static TextStyle get bodySmallLight => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    color: ColorsManager.textSecondaryLight,
    height: 1.4,
  );

  static TextStyle get bodySmallDark => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    color: ColorsManager.textSecondaryDark,
    height: 1.4,
  );

  // Button Text Styles
  static TextStyle get buttonLarge => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get buttonMedium => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get buttonSmall => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Caption and Label Styles
  static TextStyle get captionLight => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: ColorsManager.textSecondaryLight,
    height: 1.3,
  );

  static TextStyle get captionDark => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: ColorsManager.textSecondaryDark,
    height: 1.3,
  );

  static TextStyle get labelLight => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: ColorsManager.textPrimaryLight,
  );

  static TextStyle get labelDark => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: ColorsManager.textPrimaryDark,
  );

  // Error Text Style
  static TextStyle get error => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: ColorsManager.error,
  );

  // Link Text Style
  static TextStyle get link => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: ColorsManager.primaryLight,
    decoration: TextDecoration.underline,
  );

  // Price Text Style
  static TextStyle get priceLight => TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.bold,
    color: ColorsManager.primaryLight,
  );

  static TextStyle get priceDark => TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.bold,
    color: ColorsManager.primaryDark,
  );

  // App Bar Title Style
  static TextStyle get appBarTitleLight => TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.textPrimaryLight,
  );

  static TextStyle get appBarTitleDark => TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.textPrimaryDark,
  );

  // Tab Text Styles
  static TextStyle get tabSelected => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.primaryLight,
  );

  static TextStyle get tabUnselected => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: ColorsManager.grey600,
  );
}