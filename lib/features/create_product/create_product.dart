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
import 'widgets/product_type_selector.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

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

  // NEW SERVICE FIELDS
  final _customServiceCategoryController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  final _priceRangeController = TextEditingController();
  final _availabilityScheduleController = TextEditingController();
  final _skillsController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingImages = false;
  bool _isEditing = false;
  ProductType _selectedType = ProductType.item;
  String _selectedCategory = ProductCategory.others.name;
  String _selectedCondition = ProductCondition.good.name;
  String _selectedServiceCategory = ServiceCategory.others.name;
  List<File> _selectedImageFiles = [];
  List<String> _uploadedImageUrls = [];
  List<String> _tags = [];
  List<String> _skills = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.product != null;

    if (_isEditing) {
      _populateFields();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkProductLimit();
      });
    }
  }

  Future<void> _checkProductLimit() async {
    final user = UserModel.currentUser;
    if (user != null) {
      setState(() => _isLoading = true);
      final count = await FirebaseService.getUntradedProductsCount(
        user.id,
        context,
      );
      setState(() => _isLoading = false);

      if (count >= 5 && mounted) {
        await showInfoDialog(
          context: context,
          title: 'Product Limit Reached',
          message:
              'You can have at most 5 untraded items. Please trade an existing item before adding a new one.',
          icon: Icons.warning_outlined,
          iconColor: Theme.of(context).colorScheme.error,
        );
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  void _populateFields() {
    final product = widget.product!;
    _titleController.text = product.title;
    _descriptionController.text = product.description;
    _locationController.text = product.location ?? '';
    _selectedType = product.type;
    _selectedCategory = product.category;
    _selectedCondition = product.condition;
    _uploadedImageUrls = List.from(product.images);
    _tags = List.from(product.tags);
    _tagsController.text = _tags.join(', ');

    if (product.serviceCategory != null) {
      _selectedServiceCategory = product.serviceCategory!;
    }
    if (product.customServiceCategory != null) {
      _customServiceCategoryController.text = product.customServiceCategory!;
    }
    if (product.estimatedDuration != null) {
      _estimatedDurationController.text = product.estimatedDuration.toString();
    }
    if (product.priceRange != null) {
      _priceRangeController.text = product.priceRange.toString();
    }
    if (product.availabilitySchedule != null) {
      _availabilityScheduleController.text = product.availabilitySchedule!;
    }
    if (product.skills != null && product.skills!.isNotEmpty) {
      _skills = List.from(product.skills!);
      _skillsController.text = _skills.join(', ');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    _customCategoryController.dispose();
    _customServiceCategoryController.dispose();
    _estimatedDurationController.dispose();
    _priceRangeController.dispose();
    _availabilityScheduleController.dispose();
    _skillsController.dispose();
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

  void _onSkillsChanged(String value) {
    setState(() {
      _skills = value
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .toList();
    });
  }

  // ==================== IMAGE UPLOAD ====================
  Future<String?> _uploadImageToImgBB(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
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
        return data['data']['url'];
      }
      return null;
    } catch (e) {
      print('Error uploading to ImgBB: $e');
      return null;
    }
  }

  Future<List<String>> _uploadImagesToImgBB(List<File> imageFiles) async {
    setState(() => _isUploadingImages = true);
    final List<String> uploadedUrls = [];

    for (final imageFile in imageFiles) {
      if (_uploadedImageUrls.length >= 5) break;
      final url = await _uploadImageToImgBB(imageFile);
      if (url != null) {
        uploadedUrls.add(url);
        setState(() => _uploadedImageUrls.add(url));
      }
    }

    setState(() => _isUploadingImages = false);
    return uploadedUrls;
  }

  // ==================== IMAGE PICKER ====================
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
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

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library,
                  color: Theme.of(context).primaryColor),
              title: Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera,
                  color: Theme.of(context).primaryColor),
              title: Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SERVICE FIELDS ====================
  Widget _buildServiceFields() {
    return Column(
      children: [
        ServiceCategoryDropdown(
          // Service Category Dropdown

          label: 'Service Category',
          value: _selectedServiceCategory,
          onChanged: (value) {
            setState(() {
              _selectedServiceCategory = value ?? ServiceCategory.others.name;
              if (_selectedServiceCategory != ServiceCategory.others.name) {
                _customServiceCategoryController.clear();
              }
            });
          },
        ),

        // Custom Service Category
        if (_selectedServiceCategory == ServiceCategory.others.name) ...[
          SizedBox(height: 16.h),
          AuthTextField(
            label: 'Custom Service Category',
            hint: 'Enter your service category',
            controller: _customServiceCategoryController,
            validator: (value) {
              if (_selectedServiceCategory == ServiceCategory.others.name) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a service category name';
                }
                if (value.trim().length < 3) {
                  return 'Category name must be at least 3 characters';
                }
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
        ],

        SizedBox(height: 24.h),

        // Estimated Duration
        AuthTextField(
          label: 'Estimated Duration (hours)',
          hint: 'e.g., 2 for 2 hours',
          controller: _estimatedDurationController,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final duration = int.tryParse(value);
              if (duration == null || duration <= 0) {
                return 'Please enter a valid duration';
              }
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),

        SizedBox(height: 24.h),

        // Price Range (Optional)
        AuthTextField(
          label: 'Price Range (Optional)',
          hint: 'e.g., 50-100',
          controller: _priceRangeController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),

        SizedBox(height: 24.h),

        // Availability Schedule
        AuthTextField(
          label: 'Availability Schedule',
          hint: 'e.g., Weekends only, Evenings, Flexible',
          controller: _availabilityScheduleController,
          textInputAction: TextInputAction.next,
        ),

        SizedBox(height: 24.h),

        // Skills/Qualifications
        AuthTextField(
          label: 'Skills & Qualifications',
          hint: 'Enter skills separated by commas',
          controller: _skillsController,
          onChanged: _onSkillsChanged,
          maxLines: 2,
          textInputAction: TextInputAction.done,
        ),

        if (_skills.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _skills.map((skill) {
              return Chip(
                label: Text(skill, style: TextStyle(fontSize: 12.sp)),
                backgroundColor: Colors.blue.withOpacity(0.1),
                side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _skills.remove(skill);
                    _skillsController.text = _skills.join(', ');
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ==================== SAVE PRODUCT ====================
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEditing) {
      final user = UserModel.currentUser;
      if (user != null) {
        setState(() => _isLoading = true);
        final count =
            await FirebaseService.getUntradedProductsCount(user.id, context);
        if (count >= 5) {
          setState(() => _isLoading = false);
          if (mounted) {
            await showInfoDialog(
              context: context,
              title: 'Limit Reached',
              message: 'You already have 5 untraded items.',
              icon: Icons.error_outline,
              iconColor: Theme.of(context).colorScheme.error,
            );
          }
          return;
        }
      }
    }

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

    setState(() => _isLoading = true);

    try {
      final user = UserModel.currentUser;
      if (user == null) throw Exception('User not found');

      List<String> finalImageUrls = List.from(_uploadedImageUrls);

      if (_selectedImageFiles.isNotEmpty) {
        final uploadedUrls = await _uploadImagesToImgBB(_selectedImageFiles);
        if (uploadedUrls.isEmpty && _selectedImageFiles.isNotEmpty) {
          throw Exception('Failed to upload images. Please try again.');
        }
        finalImageUrls.addAll(uploadedUrls);
        _selectedImageFiles.clear();
      }

      if (finalImageUrls.isEmpty) {
        throw Exception('Failed to upload images. Please try again.');
      }

      final now = DateTime.now();
      final productId = _isEditing
          ? widget.product!.id
          : 'product_${now.millisecondsSinceEpoch}';

      // Handle custom categories
      String? customCategoryName;
      String? customServiceCategoryName;

      if (_selectedType == ProductType.item &&
          _selectedCategory == ProductCategory.others.name &&
          _customCategoryController.text.trim().isNotEmpty) {
        customCategoryName = _customCategoryController.text.trim();
        await FirebaseService.suggestCategory(
          name: customCategoryName,
          userId: user.id,
          userName: user.name,
        );
      }

      if (_selectedType == ProductType.service &&
          _selectedServiceCategory == ServiceCategory.others.name &&
          _customServiceCategoryController.text.trim().isNotEmpty) {
        customServiceCategoryName =
            _customServiceCategoryController.text.trim();
      }

      final product = ProductModel(
        id: productId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category:
            _selectedType == ProductType.item ? _selectedCategory : 'service',
        customCategory: customCategoryName,
        condition: _selectedType == ProductType.item
            ? _selectedCondition
            : 'not_applicable',
        ownerId: user.id,
        ownerName: user.name,
        images: finalImageUrls,
        createdAt: _isEditing ? widget.product!.createdAt : now,
        updatedAt: now,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        tags: _tags,
        status: _isEditing ? widget.product!.status : ProductStatus.available,
        viewCount: _isEditing ? widget.product!.viewCount : 0,
        interestedUsers: _isEditing ? widget.product!.interestedUsers : [],
        type: _selectedType,
        serviceCategory: _selectedType == ProductType.service
            ? _selectedServiceCategory
            : null,
        customServiceCategory: customServiceCategoryName,
        estimatedDuration: _selectedType == ProductType.service &&
                _estimatedDurationController.text.isNotEmpty
            ? int.tryParse(_estimatedDurationController.text)
            : null,
        priceRange: _selectedType == ProductType.service &&
                _priceRangeController.text.isNotEmpty
            ? double.tryParse(_priceRangeController.text)
            : null,
        availabilitySchedule: _selectedType == ProductType.service &&
                _availabilityScheduleController.text.isNotEmpty
            ? _availabilityScheduleController.text.trim()
            : null,
        skills: _selectedType == ProductType.service && _skills.isNotEmpty
            ? _skills
            : null,
      );

      if (_isEditing) {
        await FirebaseService.updateProductInFireStore(product, context);
      } else {
        await FirebaseService.addProductToFireStore(product, context);
      }

      if (mounted) {
        await showInfoDialog(
          context: context,
          title: _isEditing
              ? '${_selectedType.displayName} Updated'
              : '${_selectedType.displayName} Created',
          message: _isEditing
              ? 'Your ${_selectedType.displayName.toLowerCase()} has been updated successfully!'
              : 'Your ${_selectedType.displayName.toLowerCase()} has been created successfully!',
          icon: Icons.check_circle_outlined,
          iconColor: Colors.green,
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          RoutesManager.mainLayout,
          (route) => false,
        );
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
      if (mounted) setState(() => _isLoading = false);
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
      Navigator.of(context).pushNamedAndRemoveUntil(
        RoutesManager.mainLayout,
        (route) => false,
      );
    }
  }

  // ==================== BUILD METHOD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing
            ? 'Edit ${_selectedType.displayName}'
            : 'Create ${_selectedType.displayName}',
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
                  // Product Type Selector
                  ProductTypeSelector(
                    selectedType: _selectedType,
                    onChanged: (type) {
                      setState(() {
                        _selectedType = type;
                      });
                    },
                  ),

                  SizedBox(height: 32.h),

                  // Product Images Section
                  _buildImagePickerSection(),

                  SizedBox(height: 32.h),

                  // Product Title
                  AuthTextField(
                    label: _selectedType == ProductType.item
                        ? 'Item Title'
                        : 'Service Title',
                    hint: _selectedType == ProductType.item
                        ? 'Enter item title'
                        : 'Enter service title',
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

                  // Conditional rendering based on type
                  if (_selectedType == ProductType.item) ...[
                    // Item Category Dropdown
                    ProductCategoryDropdown(
                      label: 'Category',
                      value: _selectedCategory,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory =
                              value ?? ProductCategory.others.name;
                          if (_selectedCategory !=
                              ProductCategory.others.name) {
                            _customCategoryController.clear();
                          }
                        });
                      },
                    ),

                    // Custom Category Input
                    if (_selectedCategory == ProductCategory.others.name) ...[
                      SizedBox(height: 16.h),
                      AuthTextField(
                        label: 'Custom Category Name',
                        hint: 'Enter your category name',
                        controller: _customCategoryController,
                        validator: (value) {
                          if (_selectedCategory ==
                              ProductCategory.others.name) {
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
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 20.w, color: Colors.blue),
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
                  ] else ...[
                    // Show service fields
                    _buildServiceFields(),
                  ],

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
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          side: BorderSide(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.3)),
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
                    text: _isEditing
                        ? 'Update ${_selectedType.displayName}'
                        : 'Create ${_selectedType.displayName}',
                    onPressed: _saveProduct,
                    isLoading: _isLoading || _isUploadingImages,
                    height: 56.h,
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
          'Product Images',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
        ),
        SizedBox(height: 12.h),
        Container(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: totalImages + 1,
            itemBuilder: (context, index) {
              if (index == totalImages) {
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

              final isLocalFile = index < _selectedImageFiles.length;
              final imagePath = isLocalFile
                  ? _selectedImageFiles[index].path
                  : (index - _selectedImageFiles.length) <
                          _uploadedImageUrls.length
                      ? _uploadedImageUrls[index - _selectedImageFiles.length]
                      : null;

              if (imagePath == null) return SizedBox();

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
                          ? Image.file(File(imagePath), fit: BoxFit.cover)
                          : Image.network(imagePath, fit: BoxFit.cover),
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
          '${totalImages}/5 images',
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
