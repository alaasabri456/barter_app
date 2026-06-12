import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:barter/core/routes_manager/routes_manager.dart';

import '../../core/validators.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_dialog.dart';
import 'package:provider/provider.dart';
import '../products/viewmodels/product_viewmodel.dart';
import '../admin/viewmodels/admin_viewmodel.dart';
import '../../features/products/models/product_model.dart';
import '../../features/authentication/models/user_model.dart';
import '../authentication/widgets/auth_button.dart';
import '../authentication/widgets/auth_text_field.dart';
import 'widgets/product_form_field.dart';
import 'widgets/location_selection.dart';
import 'widgets/service_details_section.dart';
import 'widgets/transaction_details_section.dart';
import 'product_image_picker.dart';
import 'services/imgbb_service.dart';
import '../premium/services/premium_service.dart';

class CreateProduct extends StatefulWidget {
  final ProductModel? product;
  final ProductType? initialType;

  const CreateProduct({super.key, this.product, this.initialType});

  @override
  State<CreateProduct> createState() => _CreateProductState();
}

class _CreateProductState extends State<CreateProduct> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _customCategoryController = TextEditingController();

  // NEW SERVICE FIELDS
  final _customServiceCategoryController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  final _priceRangeController = TextEditingController();
  final _skillsController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingImages = false;
  bool _isEditing = false;

  ProductType _selectedType = ProductType.item;
  String _selectedCategory = ProductCategory.others.name;
  String _selectedCondition = ProductCondition.good.name;
  String _selectedServiceCategory = ServiceCategory.others.name;
  TransactionType _selectedTransactionType = TransactionType.barter;
  String _selectedSwapCategory = ProductCategory.electronics.name;
  String? _selectedAvailability;

  final List<XFile> _selectedImageFiles = [];
  List<String> _uploadedImageUrls = [];
  List<String> _skills = [];
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.product != null;

    if (_isEditing) {
      _populateFields();
    } else {
      if (widget.initialType != null) {
        _selectedType = widget.initialType!;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkProductLimit();
      });
    }
  }

  Future<void> _checkProductLimit() async {
    final user = UserModel.currentUser;
    if (user != null) {
      setState(() => _isLoading = true);

      final isPremium = user.isPremium;
      final limit = PremiumService.getProductLimit(isPremium);

      // Premium users have no limit (null)
      if (limit == null) {
        setState(() => _isLoading = false);
        return;
      }

      final count =
          await context.read<ProductViewModel>().getUntradedProductsCount(user.id);
      setState(() => _isLoading = false);

      if (count >= limit && mounted) {
        await showInfoDialog(
          context: context,
          title: 'Product Limit Reached',
          message:
              'You can have at most $limit untraded items. '
              'Upgrade to Premium for unlimited listings, or trade an existing item.',
          icon: Icons.warning_outlined,
          iconColor: Theme.of(context).colorScheme.error,
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
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
      _selectedAvailability = product.availabilitySchedule!;
    }
    if (product.skills != null && product.skills!.isNotEmpty) {
      _skills = List.from(product.skills!);
      _skillsController.text = _skills.join(', ');
    }
    _latitude = product.latitude;
    _longitude = product.longitude;
    _selectedTransactionType = product.transactionType;
    if (product.price != null) {
      _priceController.text = product.price.toString();
    }
    if (product.desiredSwapCategory != null) {
      _selectedSwapCategory = product.desiredSwapCategory!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _customCategoryController.dispose();
    _customServiceCategoryController.dispose();
    _estimatedDurationController.dispose();
    _priceRangeController.dispose();
    _skillsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onSkillsChanged(String value) {
    setState(() {
      _skills = value
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

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
        final uploadedUrls = await ImgbbService.uploadMultipleImages(
          _selectedImageFiles,
          onLoadingStateChanged: (loading) =>
              setState(() => _isUploadingImages = loading),
        );
        if (uploadedUrls.isEmpty && _selectedImageFiles.isNotEmpty) {
          throw Exception('Failed to upload images. Please try again.');
        }
        finalImageUrls.addAll(uploadedUrls);
      }

      if (finalImageUrls.isEmpty) {
        throw Exception('Failed to upload images. Please try again.');
      }

      final now = DateTime.now();
      final productId = _isEditing
          ? widget.product!.id
          : 'product_${now.millisecondsSinceEpoch}';

      String? customCategoryName;
      if (_selectedType == ProductType.item &&
          _selectedCategory == ProductCategory.others.name) {
        customCategoryName = _customCategoryController.text.trim();
        if (customCategoryName.isNotEmpty) {
          await context.read<AdminViewModel>().suggestCategory(
              name: customCategoryName, userId: user.id, userName: user.name);
        }
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
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        tags: const [],
        status: _isEditing ? widget.product!.status : ProductStatus.available,
        type: _selectedType,
        serviceCategory: _selectedType == ProductType.service
            ? _selectedServiceCategory
            : null,
        customServiceCategory: _selectedType == ProductType.service &&
                _selectedServiceCategory == ServiceCategory.others.name
            ? _customServiceCategoryController.text.trim()
            : null,
        estimatedDuration: _selectedType == ProductType.service
            ? int.tryParse(_estimatedDurationController.text)
            : null,
        priceRange: _selectedType == ProductType.service
            ? double.tryParse(_priceRangeController.text)
            : null,
        availabilitySchedule:
            _selectedType == ProductType.service ? _selectedAvailability : null,
        skills: _selectedType == ProductType.service && _skills.isNotEmpty
            ? _skills
            : null,
        transactionType: _selectedTransactionType,
        price: _selectedTransactionType == TransactionType.sell
            ? double.tryParse(_priceController.text)
            : null,
        desiredSwapCategory: _selectedTransactionType == TransactionType.barter
            ? _selectedSwapCategory
            : null,
      );

      if (_isEditing) {
        await context.read<ProductViewModel>().updateProduct(product);
      } else {
        await context.read<ProductViewModel>().addProduct(product);
      }

      if (mounted) {
        await showInfoDialog(
          context: context,
          title: _isEditing
              ? '${_selectedType.displayName} Updated'
              : '${_selectedType.displayName} Created',
          message:
              'Your ${_selectedType.displayName.toLowerCase()} has been ${_isEditing ? 'updated' : 'created'} successfully!',
          icon: Icons.check_circle_outlined,
          iconColor: Colors.green,
        );
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              RoutesManager.mainLayout, (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        showInfoDialog(
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
      Navigator.of(context)
          .pushNamedAndRemoveUntil(RoutesManager.mainLayout, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '${_isEditing ? 'Edit' : 'Create'} ${_selectedType.displayName}',
        leading: IconButton(
            onPressed: _showDiscardDialog, icon: const Icon(Icons.close)),
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
                  TransactionDetailsSection(
                    selectedTransactionType: _selectedTransactionType,
                    priceController: _priceController,
                    selectedSwapCategory: _selectedSwapCategory,
                    onTypeChanged: (type) =>
                        setState(() => _selectedTransactionType = type),
                    onSwapCategoryChanged: (val) => setState(() =>
                        _selectedSwapCategory =
                            val ?? ProductCategory.others.name),
                  ),
                  SizedBox(height: 32.h),
                  _buildSectionTitle('Visual Information'),
                  SizedBox(height: 16.h),
                  ProductImagePicker(
                    selectedImageFiles: _selectedImageFiles,
                    uploadedImageUrls: _uploadedImageUrls,
                    onImageFilesChanged: (files) =>
                        setState(() => _selectedImageFiles
                          ..clear()
                          ..addAll(files)),
                    onUploadedUrlsChanged: (urls) =>
                        setState(() => _uploadedImageUrls = urls),
                  ),
                  SizedBox(height: 32.h),
                  _buildSectionTitle('Item Details'),
                  SizedBox(height: 16.h),
                  AuthTextField(
                    label: '${_selectedType.displayName} Title',
                    hint:
                        'Enter ${_selectedType.displayName.toLowerCase()} title',
                    controller: _titleController,
                    validator: Validators.validateProductTitle,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 24.h),
                  AuthTextField(
                    label: 'Description',
                    hint:
                        'Describe your ${_selectedType.displayName.toLowerCase()} in detail',
                    controller: _descriptionController,
                    validator: Validators.validateProductDescription,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                  ),
                  if (_selectedType == ProductType.item) ...[
                    SizedBox(height: 24.h),
                    ProductCategoryDropdown(
                      label: 'Category',
                      value: _selectedCategory,
                      onChanged: (val) => setState(() {
                        _selectedCategory = val ?? ProductCategory.others.name;
                        if (_selectedCategory != ProductCategory.others.name) {
                          _customCategoryController.clear();
                        }
                      }),
                    ),
                    if (_selectedCategory == ProductCategory.others.name) ...[
                      SizedBox(height: 16.h),
                      AuthTextField(
                        label: 'Custom Category Name',
                        hint: 'Enter your category name',
                        controller: _customCategoryController,
                        validator: (val) {
                          if (_selectedCategory ==
                                  ProductCategory.others.name &&
                              (val == null || val.isEmpty)) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ],
                    SizedBox(height: 24.h),
                    ProductConditionDropdown(
                      label: 'Condition',
                      value: _selectedCondition,
                      onChanged: (val) => setState(() => _selectedCondition =
                          val ?? ProductCondition.good.name),
                    ),
                  ] else ...[
                    SizedBox(height: 24.h),
                    ServiceDetailsSection(
                      selectedServiceCategory: _selectedServiceCategory,
                      customCategoryController:
                          _customServiceCategoryController,
                      durationController: _estimatedDurationController,
                      priceRangeController: _priceRangeController,
                      skillsController: _skillsController,
                      skills: _skills,
                      selectedAvailability: _selectedAvailability,
                      onCategoryChanged: (val) => setState(() {
                        _selectedServiceCategory =
                            val ?? ServiceCategory.others.name;
                        if (_selectedServiceCategory !=
                            ServiceCategory.others.name)
                          _customServiceCategoryController.clear();
                      }),
                      onAvailabilityChanged: (val) =>
                          setState(() => _selectedAvailability = val),
                      onSkillsChanged: _onSkillsChanged,
                      onSkillDeleted: (skill) {
                        setState(() {
                          _skills.remove(skill);
                          _skillsController.text = _skills.join(', ');
                        });
                      },
                    ),
                  ],
                  SizedBox(height: 24.h),
                  LocationSelection(
                    controller: _locationController,
                    latitude: _latitude,
                    longitude: _longitude,
                    onLocationChanged: (lat, lng, addr) => setState(() {
                      _latitude = lat;
                      _longitude = lng;
                    }),
                  ),
                  SizedBox(height: 32.h),
                  AuthButton(
                    text:
                        '${_isEditing ? 'Update' : 'Create'} ${_selectedType.displayName}',
                    onPressed: _saveProduct,
                    isLoading: _isLoading || _isUploadingImages,
                    height: 56.h,
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
            if (_isUploadingImages)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      SizedBox(height: 16.h),
                      Text('Uploading images...',
                          style:
                              TextStyle(color: Colors.white, fontSize: 16.sp)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

extension ListExtension<T> on List<T> {
  void assignAll(Iterable<T> iterable) {
    clear();
    addAll(iterable);
  }
}
