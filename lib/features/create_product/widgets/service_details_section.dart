import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../authentication/widgets/auth_text_field.dart';
import '../../products/models/product_model.dart';
import 'product_form_field.dart';

class ServiceDetailsSection extends StatelessWidget {
  final String selectedServiceCategory;
  final TextEditingController customCategoryController;
  final TextEditingController durationController;
  final TextEditingController priceRangeController;
  final TextEditingController skillsController;
  final List<String> skills;
  final String? selectedAvailability;
  final Function(String?) onCategoryChanged;
  final Function(String?) onAvailabilityChanged;
  final Function(String) onSkillsChanged;
  final Function(String) onSkillDeleted;

  const ServiceDetailsSection({
    super.key,
    required this.selectedServiceCategory,
    required this.customCategoryController,
    required this.durationController,
    required this.priceRangeController,
    required this.skillsController,
    required this.skills,
    this.selectedAvailability,
    required this.onCategoryChanged,
    required this.onAvailabilityChanged,
    required this.onSkillsChanged,
    required this.onSkillDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ServiceCategoryDropdown(
          label: 'Service Category',
          value: selectedServiceCategory,
          onChanged: onCategoryChanged,
        ),
        if (selectedServiceCategory == ServiceCategory.others.name) ...[
          SizedBox(height: 16.h),
          AuthTextField(
            label: 'Custom Service Category',
            hint: 'Enter your service category',
            controller: customCategoryController,
            validator: (value) {
              if (selectedServiceCategory == ServiceCategory.others.name) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a service category name';
                }
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
        ],
        SizedBox(height: 24.h),
        AuthTextField(
          label: 'Estimated Duration (hours)',
          hint: 'e.g., 2 for 2 hours',
          controller: durationController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: 24.h),
        AuthTextField(
          label: 'Price Range (Optional)',
          hint: 'e.g., 50-100',
          controller: priceRangeController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: 24.h),
        ProductAvailabilityDropdown(
          label: 'Availability Schedule',
          value: selectedAvailability,
          onChanged: onAvailabilityChanged,
        ),
        SizedBox(height: 24.h),
        AuthTextField(
          label: 'Skills & Qualifications',
          hint: 'Enter skills separated by commas',
          controller: skillsController,
          onChanged: onSkillsChanged,
          maxLines: 2,
          textInputAction: TextInputAction.done,
        ),
        if (skills.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: skills.map((skill) {
              return Chip(
                label: Text(skill, style: TextStyle(fontSize: 12.sp)),
                backgroundColor: Colors.blue.withOpacity(0.1),
                side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => onSkillDeleted(skill),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
