import 'dart:io';
import 'package:barter/core/routes_manager/routes_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;

import '../../config/api_config.dart';
import '../../core/validators.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../firebase/firebase_service.dart';
import '../../features/products/models/product_model.dart';
import '../../features/authentication/models/user_model.dart';
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
  final _customCategoryController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingImages = false;
  bool _isEditing = false;
  String _selectedCategory = ProductCategory.others.name;
  String _selectedCondition = ProductCondition.good.name;
  List<File> _selectedImageFiles = []; // Store File objects
  List<String> _uploadedImageUrls = []; // Store uploaded URLs
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
    _uploadedImageUrls = List.from(product.images);
    _tags = List.from(product.tags);
    _tagsController.text = _tags.join(', ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    _customCategoryController.dispose();
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

  // ==================== IMAGE UPLOAD TO IMGBB ====================
  Future<String?> _uploadImageToImgBB(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Prepare request
      final uri = Uri.parse('https://api.imgbb.com/1/upload');

      final response = await http.post(
        uri,
        body: {
          'key': ApiConfig.imgbbApiKey,
          'image': base64Image,
          'name': path.basename(imageFile.path),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Get the image URL from response
        return data['data']['url'];
      } else {
        print('ImgBB upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading to ImgBB: $e');
      return null;
    }
  }

  // Upload multiple images to ImgBB
  Future<List<String>> _uploadImagesToImgBB(List<File> imageFiles) async {
    setState(() {
      _isUploadingImages = true;
    });

    final List<String> uploadedUrls = [];

    for (final imageFile in imageFiles) {
      if (_uploadedImageUrls.length >= 5) break; // Max 5 images

      final url = await _uploadImageToImgBB(imageFile);
      if (url != null) {
        uploadedUrls.add(url);
        setState(() {
          _uploadedImageUrls.add(url);
        });
      }
    }

    setState(() {
      _isUploadingImages = false;
    });

    return uploadedUrls;
  }

  // Alternative: Upload to Firebase Storage
  Future<List<String>> _uploadImagesToFirebase(List<File> imageFiles) async {
    setState(() {
      _isUploadingImages = true;
    });

    final List<String> uploadedUrls = [];

    setState(() {
      _isUploadingImages = false;
    });

    return uploadedUrls;
  }

  // ==================== IMAGE PICKER ====================
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
    final remainingSlots = 5 - _selectedImageFiles.length;
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
      _selectedImageFiles.addAll(filesToAdd.map((file) => File(file.path)));
    });

    // Show warning if we couldn't add all selected images
    if (pickedFiles.length > remainingSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only $remainingSlots images added (max 5)')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _selectedImageFiles.length) {
        _selectedImageFiles.removeAt(index);
      } else {
        final urlIndex = index - _selectedImageFiles.length;
        if (urlIndex < _uploadedImageUrls.length) {
          _uploadedImageUrls.removeAt(urlIndex);
        }
      }
    });
  }

  void _viewImage(int index) {
    String? imagePath;
    bool isLocalFile = index < _selectedImageFiles.length;

    if (isLocalFile) {
      imagePath = _selectedImageFiles[index].path;
    } else {
      final urlIndex = index - _selectedImageFiles.length;
      if (urlIndex < _uploadedImageUrls.length) {
        imagePath = _uploadedImageUrls[urlIndex];
      }
    }

    if (imagePath == null) return;

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
                child: isLocalFile
                    ? Image.file(
                        File(imagePath!),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImageErrorWidget();
                        },
                      )
                    : Image.network(
                        imagePath!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImageErrorWidget();
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
                  child: Icon(Icons.close, size: 20.w, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageErrorWidget() {
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
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_camera,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text('Take a Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== SAVE PRODUCT ====================
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if we have images (either uploaded or already have URLs)
    if (_selectedImageFiles.isEmpty && _uploadedImageUrls.isEmpty) {
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

      // Upload new images if any
      List<String> finalImageUrls = List.from(_uploadedImageUrls);

      if (_selectedImageFiles.isNotEmpty) {
        // Try ImgBB first, fallback to Firebase Storage
        final uploadedUrls = await _uploadImagesToImgBB(_selectedImageFiles);

        // If ImgBB fails, try Firebase Storage
        if (uploadedUrls.isEmpty && _selectedImageFiles.isNotEmpty) {
          final firebaseUrls = await _uploadImagesToFirebase(
            _selectedImageFiles,
          );
          finalImageUrls.addAll(firebaseUrls);
        } else {
          finalImageUrls.addAll(uploadedUrls);
        }

        // Clear local files after upload
        _selectedImageFiles.clear();
      }

      // Ensure we have at least one image
      if (finalImageUrls.isEmpty) {
        throw Exception('Failed to upload images. Please try again.');
      }

      final now = DateTime.now();
      final productId = _isEditing
          ? widget.product!.id
          : 'product_${now.millisecondsSinceEpoch}';

      // Handle custom category suggestion
      String? customCategoryName;
      if (_selectedCategory == ProductCategory.others.name &&
          _customCategoryController.text.trim().isNotEmpty) {
        customCategoryName = _customCategoryController.text.trim();

        // Suggest the category to admin
        try {
          await FirebaseService.suggestCategory(
            name: customCategoryName,
            userId: user.id,
            userName: user.name,
          );
        } catch (e) {
          // If suggestion fails (e.g., already exists), just log it
          print('Category suggestion note: $e');
        }
      }

      final product = ProductModel(
        id: productId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        customCategory: customCategoryName, // Store custom category if provided
        condition: _selectedCondition,
        ownerId: user.id,
        ownerName: user.name,
        images: finalImageUrls, // Store URLs, not file paths
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

      if (_isEditing) {
        await FirebaseService.updateProductInFireStore(product, context);
      } else {
        await FirebaseService.addProductToFireStore(product, context);
      }

      if (mounted) {
        await showInfoDialog(
          context: context,
          title: _isEditing ? 'Item Updated' : 'Item Created',
          message: _isEditing
              ? 'Your item has been updated successfully!'
              : customCategoryName != null
              ? 'Your item has been created! The custom category "$customCategoryName" will be reviewed by an admin.'
              : 'Your item has been created successfully!',
          icon: Icons.check_circle_outlined,
          iconColor: Colors.green,
        );

        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RoutesManager.mainLayout, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Error',
          message: 'Failed to ${_isEditing ? 'update' : 'create'} product: $e',
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
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(RoutesManager.mainLayout, (route) => false);
    }
  }

  // ==================== BUILD METHOD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'Edit Item' : 'Create Item',
        leading: IconButton(
          onPressed: _showDiscardDialog,
          icon: const Icon(Icons.close),
        ),
        actions: [
          TextButton(
            onPressed: (_isLoading || _isUploadingImages) ? null : _saveProduct,
            child: Text(
              _isEditing ? 'Update' : 'Create',
              style: TextStyle(
                color: (_isLoading || _isUploadingImages)
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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Images Section
                  _buildImagePickerSection(),

                  SizedBox(height: 32.h),

                  // Product Title
                  AuthTextField(
                    label: 'Item Title',
                    hint: 'Enter item title',
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
                        _selectedCategory =
                            value ?? ProductCategory.others.name;
                        // Clear custom category if not "others"
                        if (_selectedCategory != ProductCategory.others.name) {
                          _customCategoryController.clear();
                        }
                      });
                    },
                  ),

                  // Custom Category Input (shown when "Others" is selected)
                  if (_selectedCategory == ProductCategory.others.name) ...[
                    SizedBox(height: 16.h),
                    AuthTextField(
                      label: 'Custom Category Name',
                      hint: 'Enter your category name',
                      controller: _customCategoryController,
                      validator: (value) {
                        if (_selectedCategory == ProductCategory.others.name) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a category name';
                          }
                          if (value.trim().length < 3) {
                            return 'Category name must be at least 3 characters';
                          }
                          if (value.trim().length > 30) {
                            return 'Category name must be less than 30 characters';
                          }
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20.w,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Your custom category will be reviewed by an admin before being added to the category list.',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 24.h),

                  // Condition Dropdown
                  ProductConditionDropdown(
                    label: 'Condition',
                    value: _selectedCondition,
                    onChanged: (value) {
                      setState(() {
                        _selectedCondition =
                            value ?? ProductCondition.good.name;
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
                          label: Text(tag, style: TextStyle(fontSize: 12.sp)),
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
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
                    text: _isEditing ? 'Update Item' : 'Create Item',
                    onPressed: _saveProduct,
                    isLoading: _isLoading || _isUploadingImages,
                    height: 56,
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),

            // Uploading overlay
            if (_isUploadingImages)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16.h),
                      Text(
                        'Uploading images...',
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    final totalImages = _selectedImageFiles.length + _uploadedImageUrls.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Images',
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
            itemCount: totalImages + 1,
            itemBuilder: (context, index) {
              if (index == totalImages) {
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
              final bool isLocalFile = index < _selectedImageFiles.length;
              final String? imagePath;

              if (isLocalFile) {
                imagePath = _selectedImageFiles[index].path;
              } else {
                final urlIndex = index - _selectedImageFiles.length;
                imagePath = urlIndex < _uploadedImageUrls.length
                    ? _uploadedImageUrls[urlIndex]
                    : null;
              }

              if (imagePath == null) return SizedBox();

              return GestureDetector(
                onTap: () => _viewImage(index),
                child: Container(
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
                            ? Image.file(
                                File(imagePath),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImageContainerError();
                                },
                              )
                            : Image.network(
                                imagePath,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImageContainerError();
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
                ),
              );
            },
          ),
        ),

        SizedBox(height: 8.h),

        Row(
          children: [
            Text(
              '${totalImages}/5 images',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            if (_isUploadingImages) ...[
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

  Widget _buildImageContainerError() {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.error_outline,
          size: 32.w,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
