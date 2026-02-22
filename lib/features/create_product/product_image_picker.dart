import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImages() async {
    if (widget.selectedImages.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${widget.maxImages} images allowed'),
        ),
      );
      return;
    }

    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        final newImages = List<String>.from(widget.selectedImages);

        // Calculate how many more images we can add
        final remainingSlots = widget.maxImages - newImages.length;
        final imagesToAdd = pickedFiles.length > remainingSlots
            ? pickedFiles.sublist(0, remainingSlots)
            : pickedFiles;

        // Add the new image paths
        newImages.addAll(imagesToAdd.map((file) => file.path));

        widget.onImagesChanged?.call(newImages);

        // Show warning if we couldn't add all selected images
        if (pickedFiles.length > remainingSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Only $remainingSlots images added (max ${widget.maxImages})'),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to pick images: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (widget.selectedImages.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${widget.maxImages} images allowed'),
        ),
      );
      return;
    }

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final newImages = List<String>.from(widget.selectedImages);
        newImages.add(pickedFile.path);
        widget.onImagesChanged?.call(newImages);
      }
    } catch (e) {
      _showErrorDialog('Failed to take photo: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage(int index) {
    final newImages = List<String>.from(widget.selectedImages);
    newImages.removeAt(index);
    widget.onImagesChanged?.call(newImages);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _viewImage(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            Container(
              width: double.maxFinite,
              height: 400.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Image.file(
                File(widget.selectedImages[index]),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48.w,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8.w,
              right: 8.w,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 20.w,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                  onTap: _showImageSourceDialog,
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
              return GestureDetector(
                onTap: () => _viewImage(index),
                child: Container(
                  width: 120.w,
                  height: 120.h,
                  margin: EdgeInsets.only(right: 8.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.file(
                          File(widget.selectedImages[index]),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              child: Icon(
                                Icons.error_outline,
                                size: 32.w,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            );
                          },
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
                                horizontal: 6.w, vertical: 2.h),
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
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '${widget.selectedImages.length}/${widget.maxImages} images selected',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withOpacity(0.7),
              ),
        ),
        if (widget.selectedImages.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Text(
            'Tap image to view, tap × to remove',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.5),
                  fontSize: 10.sp,
                ),
          ),
        ],
      ],
    );
  }
}
