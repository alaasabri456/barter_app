import 'package:flutter/material.dart';
import '../resources/colors_manager.dart';

/// Helper class for gradient utilities
class GradientHelper {
  /// Get gradient for a specific category
  static LinearGradient getCategoryGradient(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return ColorsManager.electronicsGradient;
      case 'clothing':
        return ColorsManager.clothingGradient;
      case 'books':
        return ColorsManager.booksGradient;
      case 'sports':
        return ColorsManager.sportsGradient;
      case 'home':
        return ColorsManager.homeGradient;
      default:
        return ColorsManager.othersGradient;
    }
  }

  /// Get solid color for a specific category
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return ColorsManager.electronics;
      case 'clothing':
        return ColorsManager.clothing;
      case 'books':
        return ColorsManager.books;
      case 'sports':
        return ColorsManager.sports;
      case 'home':
        return ColorsManager.home;
      default:
        return ColorsManager.others;
    }
  }

  /// Create a gradient overlay for images
  static BoxDecoration imageOverlay({
    required String imageUrl,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
      gradient:
          gradient ??
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
    );
  }

  /// Glassmorphism container decoration
  static BoxDecoration glassmorphism({
    required BuildContext context,
    double blur = 10,
    double opacity = 0.1,
    Color? color,
    BorderRadius? borderRadius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: (color ?? (isDark ? Colors.white : Colors.white)).withOpacity(
        opacity,
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: blur,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Create a gradient button decoration
  static BoxDecoration gradientButton({
    Gradient? gradient,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      gradient: gradient ?? ColorsManager.primaryGradient,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      boxShadow:
          shadows ??
          [
            BoxShadow(
              color: ColorsManager.primaryLight.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
    );
  }

  /// Create a card with gradient border
  static BoxDecoration gradientBorder({
    required Gradient gradient,
    double borderWidth = 2,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: GradientBoxBorder(gradient: gradient, width: borderWidth),
    );
  }
}

/// Custom gradient border for containers
class GradientBoxBorder extends BoxBorder {
  final Gradient gradient;
  final double width;

  const GradientBoxBorder({required this.gradient, this.width = 1.0});

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  BorderSide get top => BorderSide.none;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    if (shape == BoxShape.circle) {
      canvas.drawCircle(rect.center, rect.shortestSide / 2, paint);
    } else {
      final rrect = (borderRadius ?? BorderRadius.zero).toRRect(rect);
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  ShapeBorder scale(double t) => this;
}
