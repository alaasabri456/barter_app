import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:barter/features/products/models/product_model.dart';

class CreateOfferPopup extends StatelessWidget {
  final Function(ProductType) onSelect;

  const CreateOfferPopup({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 24.w), // Placeholder for symmetry
                Text(
                  'Create Offer:',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.grey, size: 24.sp),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            _buildSelectionButton(
              context: context,
              label: 'Add Item',
              icon: Icons.inventory_2,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8C42), Color(0xFFFF5722)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              onTap: () => onSelect(ProductType.item),
            ),
            SizedBox(height: 16.h),
            _buildSelectionButton(
              context: context,
              label: 'Add Service',
              icon: Icons.handyman,
              gradient: const LinearGradient(
                colors: [Color(0xFFB388FF), Color(0xFF7C4DFF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              onTap: () => onSelect(ProductType.service),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56.h,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors[0].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 20.w),
            Icon(icon, color: Colors.white, size: 28.sp),
            SizedBox(width: 16.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
