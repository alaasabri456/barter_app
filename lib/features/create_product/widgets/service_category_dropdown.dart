// Add this to product_form_field.dart

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
          value: effectiveValue,
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
              child: Row(
                children: [
                  Icon(
                    _getServiceCategoryIcon(category),
                    size: 20.w,
                    color: _getServiceCategoryColor(category),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      category.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getServiceCategoryIcon(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.tutoring:
        return Icons.school_outlined;
      case ServiceCategory.homeCleaning:
        return Icons.cleaning_services_outlined;
      case ServiceCategory.petCare:
        return Icons.pets_outlined;
      case ServiceCategory.gardening:
        return Icons.yard_outlined;
      case ServiceCategory.repairs:
        return Icons.build_outlined;
      case ServiceCategory.photography:
        return Icons.camera_alt_outlined;
      case ServiceCategory.cooking:
        return Icons.restaurant_outlined;
      case ServiceCategory.transportation:
        return Icons.local_shipping_outlined;
      case ServiceCategory.webDevelopment:
        return Icons.code_outlined;
      case ServiceCategory.graphicDesign:
        return Icons.design_services_outlined;
      case ServiceCategory.writing:
        return Icons.edit_outlined;
      case ServiceCategory.musicLessons:
        return Icons.music_note_outlined;
      case ServiceCategory.fitness:
        return Icons.fitness_center_outlined;
      case ServiceCategory.beautyServices:
        return Icons.face_outlined;
      case ServiceCategory.eventPlanning:
        return Icons.event_outlined;
      case ServiceCategory.others:
        return Icons.more_horiz;
    }
  }

  Color _getServiceCategoryColor(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.tutoring:
        return Colors.blue;
      case ServiceCategory.homeCleaning:
        return Colors.teal;
      case ServiceCategory.petCare:
        return Colors.brown;
      case ServiceCategory.gardening:
        return Colors.green;
      case ServiceCategory.repairs:
        return Colors.orange;
      case ServiceCategory.photography:
        return Colors.purple;
      case ServiceCategory.cooking:
        return Colors.red;
      case ServiceCategory.transportation:
        return Colors.indigo;
      case ServiceCategory.webDevelopment:
        return Colors.cyan;
      case ServiceCategory.graphicDesign:
        return Colors.pink;
      case ServiceCategory.writing:
        return Colors.amber;
      case ServiceCategory.musicLessons:
        return Colors.deepPurple;
      case ServiceCategory.fitness:
        return Colors.lightGreen;
      case ServiceCategory.beautyServices:
        return Colors.pinkAccent;
      case ServiceCategory.eventPlanning:
        return Colors.deepOrange;
      case ServiceCategory.others:
        return Colors.grey;
    }
  }
}
