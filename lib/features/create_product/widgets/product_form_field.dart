// product_form_field.dart
import 'dart:io';

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
          value: effectiveValue,
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
          value: effectiveValue,
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
          value: effectiveValue,
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
          value: effectiveValue,
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

class ImagePickerGrid extends StatelessWidget {
  final List<String> imageUrls;
  final List<File> imageFiles;
  final Function() onPickImages;
  final Function(int) onRemoveImage;
  final bool isUploading;
  final int maxImages;

  const ImagePickerGrid({
    super.key,
    required this.imageUrls,
    required this.imageFiles,
    required this.onPickImages,
    required this.onRemoveImage,
    this.isUploading = false,
    this.maxImages = 5,
  });

  @override
  Widget build(BuildContext context) {
    final totalImages = imageUrls.length + imageFiles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Images',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
        ),
        SizedBox(height: 12.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 8.h,
            childAspectRatio: 1,
          ),
          itemCount: totalImages + 1,
          itemBuilder: (context, index) {
            if (index == totalImages) {
              return GestureDetector(
                onTap: totalImages >= maxImages ? null : onPickImages,
                child: Container(
                  decoration: BoxDecoration(
                    color: totalImages >= maxImages
                        ? Colors.grey[200]
                        : Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: totalImages >= maxImages
                          ? Colors.grey[300]!
                          : Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 32.w,
                        color: totalImages >= maxImages
                            ? Colors.grey[500]
                            : Theme.of(context).primaryColor,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: totalImages >= maxImages
                              ? Colors.grey[500]
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final isUrl = index < imageUrls.length;
            final imageIndex = isUrl ? index : index - imageUrls.length;
            final imagePath =
                isUrl ? imageUrls[imageIndex] : imageFiles[imageIndex].path;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: isUrl
                        ? Image.network(imagePath, fit: BoxFit.cover)
                        : Image.file(File(imagePath), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4.w,
                    right: 4.w,
                    child: GestureDetector(
                      onTap: () => onRemoveImage(index),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(Icons.close, size: 16.w, color: Colors.white),
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      bottom: 4.w,
                      left: 4.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'Main',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Text(
              '${totalImages}/$maxImages images',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            if (isUploading) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12.w,
                      height: 12.h,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Uploading',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class TagsInputField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> tags;
  final ValueChanged<String> onChanged;
  final Function(String) onTagDeleted;

  const TagsInputField({
    super.key,
    required this.controller,
    required this.tags,
    required this.onChanged,
    required this.onTagDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText:
                'Enter tags separated by commas (e.g., electronics, used, cheap)',
            prefixIcon: Icon(
              Icons.tag_outlined,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
              size: 20.w,
            ),
          ),
        ),
        if (tags.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: tags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: Icon(Icons.close, size: 16.w),
                onDeleted: () => onTagDeleted(tag),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class SkillsInputField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> skills;
  final ValueChanged<String> onChanged;
  final Function(String) onSkillDeleted;

  const SkillsInputField({
    super.key,
    required this.controller,
    required this.skills,
    required this.onChanged,
    required this.onSkillDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills & Qualifications',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          maxLines: 2,
          decoration: InputDecoration(
            hintText:
                'Enter skills separated by commas (e.g., Web Development, Photography, Cooking)',
            prefixIcon: Icon(
              Icons.school_outlined,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
              size: 20.w,
            ),
          ),
        ),
        if (skills.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: skills.map((skill) {
              return Chip(
                label: Text(skill),
                backgroundColor: Colors.blue.withOpacity(0.1),
                deleteIcon: Icon(Icons.close, size: 16.w),
                onDeleted: () => onSkillDeleted(skill),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
