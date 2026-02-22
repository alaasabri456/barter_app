// product_form_field.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../products/models/product_model.dart';

class ServiceCategoryDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String? hint;

  const ServiceCategoryDropdown({
    super.key,
    required this.label,
    this.value,
    this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    String? effectiveValue = value;
    if (value != null && !ServiceCategory.values.any((e) => e.name == value)) {
      effectiveValue = ServiceCategory.others.name;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: effectiveValue,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint ?? 'Select service category',
            prefixIcon: Icon(
              Icons.work_outline,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
              size: 20.w,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a service category';
            }
            return null;
          },
          items: ServiceCategory.values.map((category) {
            return DropdownMenuItem<String>(
              value: category.name,
              child: Text(category.displayName),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ProductCategoryDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String? hint;

  const ProductCategoryDropdown({
    super.key,
    required this.label,
    this.value,
    this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    String? effectiveValue = value;
    if (value != null && !ProductCategory.values.any((e) => e.name == value)) {
      effectiveValue = ProductCategory.others.name;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: effectiveValue,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint ?? 'Select category',
            prefixIcon: Icon(
              Icons.category_outlined,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
              size: 20.w,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
          items: ProductCategory.values.map((category) {
            return DropdownMenuItem<String>(
              value: category.name,
              child: Text(category.displayName),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ProductConditionDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String? hint;

  const ProductConditionDropdown({
    super.key,
    required this.label,
    this.value,
    this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    String? effectiveValue = value;
    if (value != null && !ProductCondition.values.any((e) => e.name == value)) {
      effectiveValue = ProductCondition.good.name;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: effectiveValue,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint ?? 'Select condition',
            prefixIcon: Icon(
              Icons.assessment_outlined,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
              size: 20.w,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a condition';
            }
            return null;
          },
          items: ProductCondition.values.map((condition) {
            return DropdownMenuItem<String>(
              value: condition.name,
              child: Text(condition.displayName),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ProductStatusDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String? hint;

  const ProductStatusDropdown({
    super.key,
    required this.label,
    this.value,
    this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    String? effectiveValue = value;
    if (value != null && !ProductStatus.values.any((e) => e.name == value)) {
      effectiveValue = ProductStatus.available.name;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: effectiveValue,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint ?? 'Select status',
            prefixIcon: Icon(
              Icons.info_outline,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
              size: 20.w,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a status';
            }
            return null;
          },
          items: ProductStatus.values.map((status) {
            return DropdownMenuItem<String>(
              value: status.name,
              child: Text(status.displayName),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ProductAvailabilityDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String? hint;

  const ProductAvailabilityDropdown({
    super.key,
    required this.label,
    this.value,
    this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    String? effectiveValue = value;
    if (value != null &&
        !ProductAvailability.values.any((e) => e.name == value)) {
      effectiveValue = ProductAvailability.flexible.name;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          initialValue: effectiveValue,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint ?? 'Select availability',
            prefixIcon: Icon(
              Icons.calendar_today_outlined,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
              size: 20.w,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select availability';
            }
            return null;
          },
          items: ProductAvailability.values.map((availability) {
            return DropdownMenuItem<String>(
              value: availability.name,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getAvailabilityIcon(availability),
                    size: 20.w,
                    color: _getAvailabilityColor(availability),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    availability.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getAvailabilityIcon(ProductAvailability availability) {
    switch (availability) {
      case ProductAvailability.weekdays:
        return Icons.work_outline;
      case ProductAvailability.weekends:
        return Icons.weekend_outlined;
      case ProductAvailability.flexible:
        return Icons.sync_outlined;
      case ProductAvailability.byAppointment:
        return Icons.event_available_outlined;
    }
  }

  Color _getAvailabilityColor(ProductAvailability availability) {
    switch (availability) {
      case ProductAvailability.weekdays:
        return Colors.blue;
      case ProductAvailability.weekends:
        return Colors.orange;
      case ProductAvailability.flexible:
        return Colors.green;
      case ProductAvailability.byAppointment:
        return Colors.purple;
    }
  }
}
