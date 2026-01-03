// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../products/models/product_model.dart';

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
    // Ensure the value exists in the enum items, otherwise default to 'others'
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
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 20.w,
                    color: _getCategoryColor(category),
                  ),
                  SizedBox(width: 12.w),
                  Text(category.displayName),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(ProductCategory category) {
    switch (category) {
      case ProductCategory.electronics:
        return Icons.phone_android;
      case ProductCategory.clothing:
        return Icons.checkroom;
      case ProductCategory.books:
        return Icons.menu_book;
      case ProductCategory.sports:
        return Icons.sports_football;
      case ProductCategory.home:
        return Icons.home;
      case ProductCategory.toys:
        return Icons.toys;
      case ProductCategory.automotive:
        return Icons.directions_car;
      case ProductCategory.jewelry:
        return Icons.diamond;
      case ProductCategory.health:
        return Icons.health_and_safety;
      case ProductCategory.others:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(ProductCategory category) {
    switch (category) {
      case ProductCategory.electronics:
        return Colors.blue;
      case ProductCategory.clothing:
        return Colors.purple;
      case ProductCategory.books:
        return Colors.brown;
      case ProductCategory.sports:
        return Colors.green;
      case ProductCategory.home:
        return Colors.orange;
      case ProductCategory.toys:
        return Colors.pink;
      case ProductCategory.automotive:
        return Colors.red;
      case ProductCategory.jewelry:
        return Colors.amber;
      case ProductCategory.health:
        return Colors.teal;
      case ProductCategory.others:
        return Colors.grey;
    }
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
          value: value,
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
              child: Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getConditionColor(condition),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(condition.displayName),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getConditionColor(ProductCondition condition) {
    switch (condition) {
      case ProductCondition.new_item:
        return Colors.green;
      case ProductCondition.like_new:
        return Colors.lightGreen;
      case ProductCondition.good:
        return Colors.orange;
      case ProductCondition.fair:
        return Colors.deepOrange;
      case ProductCondition.poor:
        return Colors.red;
    }
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
          value: value,
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
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 20.w,
                    color: _getStatusColor(status),
                  ),
                  SizedBox(width: 12.w),
                  Text(status.displayName),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getStatusIcon(ProductStatus status) {
    switch (status) {
      case ProductStatus.available:
        return Icons.check_circle_outline;
      case ProductStatus.traded:
        return Icons.swap_horiz;
      case ProductStatus.reserved:
        return Icons.schedule;
      case ProductStatus.unavailable:
        return Icons.cancel_outlined;
    }
  }

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.available:
        return Colors.green;
      case ProductStatus.traded:
        return Colors.orange;
      case ProductStatus.reserved:
        return Colors.blue;
      case ProductStatus.unavailable:
        return Colors.grey;
    }
  }
}

class ProductImagePicker extends StatefulWidget {
  final List<String> selectedImages;
  final ValueChanged<List<String>>? onImagesChanged;
  final int maxImages;

  const ProductImagePicker({
    super.key,
    required this.selectedImages,
    this.onImagesChanged,
    this.maxImages = 5,
  });

  @override
  State<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  void _addImage() {
    if (widget.selectedImages.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum ${widget.maxImages} images allowed')),
      );
      return;
    }

    // Simulate image picking
    final newImages = List<String>.from(widget.selectedImages);
    newImages.add('image_${DateTime.now().millisecondsSinceEpoch}');
    widget.onImagesChanged?.call(newImages);
  }

  void _removeImage(int index) {
    final newImages = List<String>.from(widget.selectedImages);
    newImages.removeAt(index);
    widget.onImagesChanged?.call(newImages);
  }

  @override
  Widget build(BuildContext context) {
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
        SizedBox(height: 8.h),

        SizedBox(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == widget.selectedImages.length) {
                // Add image button
                return GestureDetector(
                  onTap: _addImage,
                  child: Container(
                    width: 120.w,
                    height: 120.h,
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32.w,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Image item
              return Container(
                width: 120.w,
                height: 120.h,
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.image,
                          size: 32.w,
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4.w,
                      right: 4.w,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16.w,
                            color: Colors.white,
                          ),
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
        ),

        SizedBox(height: 8.h),

        Text(
          '${widget.selectedImages.length}/${widget.maxImages} images selected',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
