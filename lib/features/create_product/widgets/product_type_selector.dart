import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../products/models/product_model.dart';

class ProductTypeSelector extends StatelessWidget {
  final ProductType selectedType;
  final ValueChanged<ProductType> onChanged;

  const ProductTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTypeButton(
                  context: context,
                  type: ProductType.item,
                  icon: Icons.inventory_2_outlined,
                  label: 'Item',
                ),
              ),
              Expanded(
                child: _buildTypeButton(
                  context: context,
                  type: ProductType.service,
                  icon: Icons.handshake_outlined,
                  label: 'Service',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton({
    required BuildContext context,
    required ProductType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedType == type;
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () => onChanged(type),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32.w,
              color: isSelected
                  ? primaryColor
                  : Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? primaryColor
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
