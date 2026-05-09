import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Reusable premium badge widget that displays a golden crown/star indicator.
///
/// Two variants:
/// - **compact**: Small crown icon for product cards and list tiles.
/// - **full**: Larger badge with label text for profile headers.
class PremiumBadgeWidget extends StatelessWidget {
  /// If `true`, shows the compact (icon-only) variant.
  final bool compact;

  /// Optional label text (only used in full variant).
  final String label;

  /// Icon size override.
  final double? size;

  const PremiumBadgeWidget({
    super.key,
    this.compact = false,
    this.label = 'Premium',
    this.size,
  });

  /// Compact constructor for product cards.
  const PremiumBadgeWidget.compact({super.key})
      : compact = true,
        label = '',
        size = null;

  /// Full constructor for profile headers.
  const PremiumBadgeWidget.full({super.key, this.label = 'Premium'})
      : compact = false,
        size = null;

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact(context) : _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    final iconSize = size ?? 16.w;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: _premiumGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB800).withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.workspace_premium,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: _premiumGradient,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB800).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            size: size ?? 16.w,
            color: Colors.white,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  static const LinearGradient _premiumGradient = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFFF8C00), Color(0xFFE65100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
