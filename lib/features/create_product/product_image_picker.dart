import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/widgets/custom_dialog.dart';

class ProductImagePicker extends StatelessWidget {
  final List<XFile> selectedImageFiles;
  final List<String> uploadedImageUrls;
  final Function(List<XFile>) onImageFilesChanged;
  final Function(List<String>) onUploadedUrlsChanged;
  final int maxImages;

  const ProductImagePicker({
    super.key,
    required this.selectedImageFiles,
    required this.uploadedImageUrls,
    required this.onImageFilesChanged,
    required this.onUploadedUrlsChanged,
    this.maxImages = 5,
  });

  Future<void> _pickImages(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final source = await _showImageSourceDialog(context);
    if (source == null) return;

    try {
      if (source == ImageSource.gallery) {
        final List<XFile> pickedFiles = await picker.pickMultiImage(
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 80,
        );
        if (pickedFiles.isNotEmpty) {
          _addSelectedImages(context, pickedFiles);
        }
      } else {
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 80,
        );
        if (pickedFile != null) {
          _addSelectedImages(context, [pickedFile]);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showInfoDialog(
          context: context,
          title: 'Error',
          message: 'Failed to pick images: $e',
          icon: Icons.error_outline,
          iconColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  void _addSelectedImages(BuildContext context, List<XFile> pickedFiles) {
    final totalCurrent = selectedImageFiles.length + uploadedImageUrls.length;
    final remainingSlots = maxImages - totalCurrent;

    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $maxImages images allowed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final filesToAdd = pickedFiles.length > remainingSlots
        ? pickedFiles.sublist(0, remainingSlots)
        : pickedFiles;

    final newList = List<XFile>.from(selectedImageFiles);
    newList.addAll(filesToAdd);
    onImageFilesChanged(newList);

    if (pickedFiles.length > remainingSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Only $remainingSlots images added (max $maxImages)')),
      );
    }
  }

  void _removeImage(int index) {
    if (index < selectedImageFiles.length) {
      final newList = List<XFile>.from(selectedImageFiles);
      newList.removeAt(index);
      onImageFilesChanged(newList);
    } else {
      final urlIndex = index - selectedImageFiles.length;
      if (urlIndex < uploadedImageUrls.length) {
        final newList = List<String>.from(uploadedImageUrls);
        newList.removeAt(urlIndex);
        onUploadedUrlsChanged(newList);
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library,
                  color: Theme.of(context).primaryColor),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera,
                  color: Theme.of(context).primaryColor),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = selectedImageFiles.length + uploadedImageUrls.length;

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
        SizedBox(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: totalImages + 1,
            itemBuilder: (context, index) {
              if (index == totalImages) {
                return GestureDetector(
                  onTap: () => _pickImages(context),
                  child: Container(
                    width: 120.w,
                    height: 120.h,
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
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

              final isLocalFile = index < selectedImageFiles.length;
              final imagePath = isLocalFile
                  ? selectedImageFiles[index].path
                  : uploadedImageUrls[index - selectedImageFiles.length];

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
                      child: isLocalFile
                          ? (kIsWeb
                              ? Image.network(imagePath,
                                  fit: BoxFit.cover,
                                  width: 120.w,
                                  height: 120.h)
                              : Image.file(File(imagePath),
                                  fit: BoxFit.cover,
                                  width: 120.w,
                                  height: 120.h))
                          : Image.network(imagePath,
                              fit: BoxFit.cover, width: 120.w, height: 120.h),
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
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '$totalImages/$maxImages images',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withOpacity(0.7),
              ),
        ),
      ],
    );
  }
}
