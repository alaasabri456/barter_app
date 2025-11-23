import 'dart:io';
import 'package:barter/core/routes_manager/routes_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/validators.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../firebase/firebase_service.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../authentication/widgets/auth_button.dart';
import '../authentication/widgets/auth_text_field.dart';
import 'widgets/product_form_field.dart';

class CreateProduct extends StatefulWidget {
  final ProductModel? product;

  const CreateProduct({super.key, this.product});

  @override
  State<CreateProduct> createState() => _CreateProductState();
}

class _CreateProductState extends State<CreateProduct> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  String _selectedCategory = ProductCategory.others.name;
  String _selectedCondition = ProductCondition.good.name;
  List<String> _selectedImages = [];
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.product != null;

    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final product = widget.product!;
    _titleController.text = product.title;
    _descriptionController.text = product.description;
    _locationController.text = product.location ?? '';
    _selectedCategory = product.category;
    _selectedCondition = product.condition;
    _selectedImages = List.from(product.images);
    _tags = List.from(product.tags);
    _tagsController.text = _tags.join(', ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _onTagsChanged(String value) {
    setState(() {
      _tags = value
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    });
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();

    // Show option to choose between gallery and camera
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      if (source == ImageSource.gallery) {
        final List<XFile>? pickedFiles = await picker.pickMultiImage(
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 80,
        );

        if (pickedFiles != null && pickedFiles.isNotEmpty) {
          _addSelectedImages(pickedFiles);
        }
      } else {
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          _addSelectedImages([pickedFile]);
        }
      }
    } catch (e) {
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Error',
          message: 'Failed to pick images: $e',
          icon: Icons.error_outline,
          iconColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  void _addSelectedImages(List<XFile> pickedFiles) {
    final remainingSlots = 5 - _selectedImages.length;
    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 5 images allowed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final filesToAdd = pickedFiles.length > remainingSlots
        ? pickedFiles.sublist(0, remainingSlots)
        : pickedFiles;

    setState(() {
      _selectedImages.addAll(filesToAdd.map((file) => file.path));
    });

    // Show warning if we couldn't add all selected images
    if (pickedFiles.length > remainingSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only $remainingSlots images added (max 5)'),
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _viewImage(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              width: double.maxFinite,
              height: 400.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.file(
                  File(_selectedImages[index]),
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

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Theme.of(context).primaryColor),
                title: Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: Theme.of(context).primaryColor),
                title: Text('Take a Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      await showInfoDialog(
        context: context,
        title: 'Images Required',
        message: 'Please add at least one image for your product.',
        icon: Icons.warning_outlined,
        iconColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = UserModel.currentUser;
      if (user == null) throw Exception('User not found');

      final now = DateTime.now();
      final productId =
      _isEditing ? widget.product!.id : 'product_${now.millisecondsSinceEpoch}';

      final product = ProductModel(
        id: productId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        condition: _selectedCondition,
        ownerId: user.id,
        ownerName: user.name,
        images: _selectedImages,
        createdAt: _isEditing ? widget.product!.createdAt : now,
        updatedAt: now,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        tags: _tags,
        status: _isEditing ? widget.product!.status : ProductStatus.available,
        viewCount: _isEditing ? widget.product!.viewCount : 0,
        interestedUsers: _isEditing ? widget.product!.interestedUsers : [],
      );

      await FirebaseService.addProductToFireStore(product, context);
Navigator.pushReplacementNamed(context,RoutesManager.mainLayout);
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: _isEditing ? 'Product Updated' : 'Product Created',
          message: _isEditing
              ? 'Your product has been updated successfully!'
              : 'Your product has been created successfully!',
          icon: Icons.check_circle_outlined,
          iconColor: Colors.green,
        );

        Navigator.of(context).pop(product);
      }
    } catch (e) {
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Error',
          message:
          'Failed to ${_isEditing ? 'update' : 'create'} product. Please try again.',
          icon: Icons.error_outline,
          iconColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDiscardDialog() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Discard Changes',
      message: 'Are you sure you want to discard your changes?',
      confirmText: 'Discard',
      cancelText: 'Keep Editing',
      icon: Icons.warning_outlined,
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'Edit Product' : 'Create Product',
        leading: IconButton(
          onPressed: _showDiscardDialog,
          icon: const Icon(Icons.close),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProduct,
            child: Text(
              _isEditing ? 'Update' : 'Create',
              style: TextStyle(
                color: _isLoading
                    ? Theme.of(context).disabledColor
                    : Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Images Section
              _buildImagePickerSection(),

              SizedBox(height: 32.h),

              // Product Title
              AuthTextField(
                label: 'Product Title',
                hint: 'Enter product title',
                controller: _titleController,
                validator: Validators.validateProductTitle,
                textInputAction: TextInputAction.next,
              ),

              SizedBox(height: 24.h),

              // Product Description
              AuthTextField(
                label: 'Description',
                hint: 'Describe your product in detail',
                controller: _descriptionController,
                validator: Validators.validateProductDescription,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),

              SizedBox(height: 24.h),

              // Category Dropdown
              ProductCategoryDropdown(
                label: 'Category',
                value: _selectedCategory,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? ProductCategory.others.name;
                  });
                },
              ),

              SizedBox(height: 24.h),

              // Condition Dropdown
              ProductConditionDropdown(
                label: 'Condition',
                value: _selectedCondition,
                onChanged: (value) {
                  setState(() {
                    _selectedCondition = value ?? ProductCondition.good.name;
                  });
                },
              ),

              SizedBox(height: 24.h),

              // Location (Optional)
              AuthTextField(
                label: 'Location (Optional)',
                hint: 'Enter your location',
                controller: _locationController,
                textInputAction: TextInputAction.next,
              ),

              SizedBox(height: 24.h),

              // Tags
              AuthTextField(
                label: 'Tags (Optional)',
                hint: 'Enter tags separated by commas',
                controller: _tagsController,
                onChanged: _onTagsChanged,
                textInputAction: TextInputAction.done,
              ),

              if (_tags.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      side: BorderSide(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _tags.remove(tag);
                          _tagsController.text = _tags.join(', ');
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 24.h),
              ],

              // Save Button
              AuthButton(
                text: _isEditing ? 'Update Product' : 'Create Product',
                onPressed: _saveProduct,
                isLoading: _isLoading,
                height: 56,
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
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

        Container(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                // Add image button
                return GestureDetector(
                  onTap: _pickImages,
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
                          File(_selectedImages[index]),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
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
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
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
          '${_selectedImages.length}/5 images selected',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),

        // if (_selectedImages.isNotEmpty) ...[
        //   SizedBox(height: 4.h),
        //   Text(
        //     'Tap image to view, tap × to remove',
        //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
        //       color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
        //       fontSize: 10.sp,
        //     ),
        //   ),
        // ],
      ],
    );
  }
}