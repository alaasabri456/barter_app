// features/product_details/product_details_screen.dart
// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import '../products/viewmodels/product_viewmodel.dart';
import '../admin/viewmodels/admin_viewmodel.dart';
import '../trade/viewmodels/trade_viewmodel.dart';
import '../../features/products/models/product_model.dart';
import '../../features/authentication/models/user_model.dart';
import '../authentication/widgets/auth_button.dart';
import '../chat/chat_screen.dart';
import '../trade/trade_initiation_screen.dart';
import '../create_product/create_product.dart';
import '../payment/checkout_screen.dart';
import '../profile/public_profile_screen.dart';
import '../../core/routes_manager/routes_manager.dart';
import '../admin/models/report_model.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  final ProductModel? initialProduct;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  ProductModel? _product;
  bool _isLoading = true;
  bool _errorLoading = false;
  int _selectedImageIndex = 0;
  bool _isFavourite = false;
  bool _isFavouriteLoading = false;
  int _pendingTradeCount = 0;

  @override
  void initState() {
    super.initState();
    _product = widget.initialProduct;
    _isLoading = _product == null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductDetails();
    });
  }

  List<String> get _productFetchIds {
    final ids = <String>[];

    void addId(String? id) {
      if (id != null && id.isNotEmpty && !ids.contains(id)) {
        ids.add(id);
      }
    }

    addId(widget.productId);
    addId(widget.initialProduct?.id);
    addId(_product?.id);
    return ids;
  }

  String get _activeProductId {
    final productId = _product?.id;
    if (productId != null && productId.isNotEmpty) {
      return productId;
    }
    return widget.productId;
  }

  Future<ProductModel?> _fetchProductWithFallback() async {
    final productViewModel = context.read<ProductViewModel>();

    for (final productId in _productFetchIds) {
      try {
        final product = await productViewModel.getProductById(productId);
        if (product != null) return product;
      } catch (e) {
        print('Failed to fetch product $productId: $e');
      }
    }

    return _product;
  }

  Future<void> _loadProductDetails() async {
    if (mounted) {
      setState(() {
        _isLoading = _product == null;
        _errorLoading = false;
      });
    }

    try {
      // Increment view count (fire and forget - don't block loading)
      final userId = UserModel.currentUser?.id ?? '';
      final viewProductId = _activeProductId;
      if (userId.isNotEmpty && viewProductId.isNotEmpty) {
        context.read<ProductViewModel>().incrementProductViewCount(
          viewProductId,
          userId,
        ).catchError((e) {
          print('Failed to increment view count: $e');
        });
      }

      // Load product details
      final product = await _fetchProductWithFallback();
      if (!mounted) return;

      setState(() {
        _product = product;
        _errorLoading = product == null;
        _isLoading = false;
      });

      if (product == null) return;

      final productId = product.id.isNotEmpty ? product.id : widget.productId;
      if (productId.isEmpty) return;

      // Load favorite status
      await _loadFavouriteStatus(productId);

      // Load pending trade count
      final count = await context
          .read<TradeViewModel>()
          .getPendingTradeCountForProduct(productId);
      if (mounted) {
        setState(() {
          _pendingTradeCount = count;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorLoading = _product == null;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavouriteStatus([String? productId]) async {
    final userId = UserModel.currentUser?.id;
    if (userId == null) return;

    final targetProductId = productId ?? _activeProductId;
    if (targetProductId.isEmpty) return;

    try {
      final isFav = await context
          .read<ProductViewModel>()
          .isFavourite(userId, targetProductId);
      if (mounted) {
        setState(() {
          _isFavourite = isFav;
        });
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> _toggleFavourite() async {
    print('=== FAVORITE BUTTON CLICKED ===');

    final userId = UserModel.currentUser?.id;
    print('User ID: $userId');

    if (userId == null || UserModel.isGuest) {
      print('User not logged in or is guest');
      showConfirmationDialog(
        context: context,
        title: 'Sign in Required',
        message: 'Please sign in to add products to your favorites.',
        confirmText: 'Sign In',
        cancelText: 'Maybe Later',
        icon: Icons.login,
      ).then((value) {
        if (value == true) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(RoutesManager.login, (route) => false);
        }
      });
      return;
    }

    print('Setting loading state...');
    setState(() {
      _isFavouriteLoading = true;
    });

    try {
      print('Calling toggleFavourite for product: ${widget.productId}');
      final newStatus = await context.read<ProductViewModel>().toggleFavourite(
        userId,
        widget.productId,
      );
      print('Toggle successful! New status: $newStatus');

      if (mounted) {
        setState(() {
          _isFavourite = newStatus;
          _isFavouriteLoading = false;

          // Update local product interested count
          if (_product != null) {
            final currentInterested = List<String>.from(
              _product!.interestedUsers,
            );
            if (newStatus) {
              if (!currentInterested.contains(userId)) {
                currentInterested.add(userId);
              }
            } else {
              currentInterested.remove(userId);
            }

            _product = _product!.copyWith(interestedUsers: currentInterested);
          }
        });

        print('Showing snackbar...');
        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Added to favorites' : 'Removed from favorites',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('=== ERROR TOGGLING FAVORITE: $e ===');
      if (mounted) {
        setState(() {
          _isFavouriteLoading = false;
        });

        // Show detailed error for debugging
        showInfoDialog(
          context: context,
          title: 'Error',
          message: 'Failed to update favorites: ${e.toString()}',
          icon: Icons.error_outline,
          iconColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  void _showImageGallery() {
    if (_product?.images.isEmpty ?? true) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: Colors.white, size: 30.w),
              ),
            ),
            Container(
              height: 300.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                image: _product!.images.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(
                          _product!.images[_selectedImageIndex],
                        ),
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
            ),
            if (_product!.images.length > 1) ...[
              SizedBox(height: 16.h),
              SizedBox(
                height: 60.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _product!.images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImageIndex = index;
                        });
                      },
                      child: Container(
                        width: 60.w,
                        height: 60.h,
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: _selectedImageIndex == index
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(_product!.images[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _initiateTrade() {
    if (UserModel.isGuest) {
      _showGuestLoginPrompt();
      return;
    }
    if (_product != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InitiateTradeScreen(
            targetProduct: _product!,
            isCounterOffer: _pendingTradeCount > 0,
          ),
        ),
      );
    }
  }

  void _showGuestLoginPrompt() {
    showConfirmationDialog(
      context: context,
      title: 'Sign In Required',
      message: 'You need to sign in to access this feature.',
      confirmText: 'Sign In',
      cancelText: 'Maybe Later',
      icon: Icons.login,
    ).then((value) {
      if (value == true) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RoutesManager.login, (route) => false);
      }
    });
  }

  void _contactOwner() async {
    final currentUserId = UserModel.currentUser?.id;

    if (currentUserId == null || UserModel.isGuest) {
      _showGuestLoginPrompt();
      return;
    }

    if (_product == null) return;

    // Navigate directly to chat screen with product context
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUserId: _product!.ownerId,
          otherUserName: _product!.ownerName,
          productTitle: _product!.title,
          productId: _product!.id,
        ),
      ),
    );
  }

  void _reportProduct() {
    if (UserModel.isGuest || UserModel.currentUser == null) {
      _showGuestLoginPrompt();
      return;
    }
    if (_product == null) return;
    if (_product!.ownerId == UserModel.currentUser!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot report your own item.')),
      );
      return;
    }

    ReportReason? selectedReason;
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Report Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why are you reporting this item?',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
                    ),
                    SizedBox(height: 12.h),
                    ...ReportReason.values.map((reason) {
                      return RadioListTile<ReportReason>(
                        title: Text(reason.displayName, style: TextStyle(fontSize: 14.sp)),
                        value: reason,
                        groupValue: selectedReason,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setDialogState(() {
                            selectedReason = val;
                          });
                        },
                      );
                    }),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Additional details (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () => Navigator.pop(context, {
                            'reason': selectedReason,
                            'description': descriptionController.text.trim(),
                          }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit Report'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) async {
      if (result == null) return;

      final reason = result['reason'] as ReportReason;
      final description = result['description'] as String;
      final userId = UserModel.currentUser!.id;

      try {
        // 1. Update reportedByUserIds on the product (existing behavior)
        await context.read<ProductViewModel>().reportProduct(
          productId: _product!.id,
          userId: userId,
        );

        // 2. Create a detailed report document
        final report = ReportModel(
          id: '${_product!.id}_${userId}_${DateTime.now().millisecondsSinceEpoch}',
          reporterId: userId,
          reporterName: UserModel.currentUser!.name,
          reportedProductId: _product!.id,
          reportedProductTitle: _product!.title,
          reportedProductOwnerId: _product!.ownerId,
          reason: reason,
          description: description,
          createdAt: DateTime.now(),
        );
        await context.read<AdminViewModel>().submitReport(report);

        // 3. Notify admin(s) via system notification
        await context.read<AdminViewModel>().notifyAdminsOfReport(report);

        if (mounted) {
          showInfoDialog(
            context: context,
            title: 'Report Submitted',
            message: 'Thank you for reporting. Our admin team has been notified and will review this item shortly.',
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );
          _loadProductDetails();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to report: $e')),
          );
        }
      }
    });
  }

  void _shareProduct() {
    if (_product == null) return;
    Share.share(
      'Check out this item on Barter: ${_product!.title}\n\n${_product!.description}\n\nCondition: ${_product!.condition}',
      subject: 'Check out ${_product!.title}',
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 20.w, color: Theme.of(context).primaryColor),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: 16.w,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProduct = _product?.ownerId == UserModel.currentUser?.id;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Item Details',
        actions: [
          IconButton(
            onPressed: _shareProduct,
            icon: Icon(Icons.share_outlined),
            tooltip: 'Share Item',
          ),
          if (!isOwnProduct)
            IconButton(
              onPressed: _reportProduct,
              icon: Icon(Icons.flag_outlined),
              tooltip: 'Report Item',
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        loadingMessage: 'Loading product details...',
        child: _product != null
            ? _buildProductDetails(isOwnProduct)
            : _isLoading
                ? const SizedBox.shrink()
                : _errorLoading
                    ? _buildErrorState()
                    : _buildEmptyState(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.w,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(height: 16.h),
          Text(
            'Failed to load product',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8.h),
          Text(
            'Please check your connection and try again',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          AuthButton(
            text: 'Try Again',
            onPressed: _loadProductDetails,
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64.w,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            'Product not found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8.h),
          Text(
            'The product you\'re looking for doesn\'t exist or has been removed',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails(bool isOwnProduct) {
    final product = _product!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 100.h), // Space for bottom button
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Gallery
                _buildImageSection(product),

                // Product Info
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Category
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: product.status == ProductStatus.available
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: product.status == ProductStatus.available
                                    ? Colors.green
                                    : Colors.grey,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  product.status == ProductStatus.available
                                      ? Icons.check_circle
                                      : Icons.block,
                                  size: 14.w,
                                  color:
                                      product.status == ProductStatus.available
                                          ? Colors.green
                                          : Colors.grey,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  product.status.displayName,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: product.status ==
                                            ProductStatus.available
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_pendingTradeCount > 0) ...[
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.orange,
                                size: 20.w,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  '$_pendingTradeCount active offer${_pendingTradeCount > 1 ? 's' : ''} pending for this item. You can still send a counter offer!',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Text(
                              product.category,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getConditionColor(
                                product.condition,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Text(
                              product.condition,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: _getConditionColor(product.condition),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Transaction Type Info
                      Row(
                        children: [
                          Icon(
                            product.transactionType == TransactionType.sell
                                ? Icons.attach_money
                                : Icons.swap_horiz,
                            size: 20.w,
                            color: Theme.of(context).primaryColor,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              product.transactionType == TransactionType.sell
                                  ? 'Price: \$${product.price?.toStringAsFixed(2) ?? "0.00"}'
                                  : 'For Barter (Swap with: ${product.desiredSwapCategory ?? "Any"})',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color:
                                    Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        product.description,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                      SizedBox(height: 24.h),

                      // Product Details
                      Text(
                        'Item Details',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12.h),
                      _buildInfoRow(
                        Icons.person_outline,
                        'Owner',
                        product.ownerName,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PublicProfileScreen(
                                userId: product.ownerId,
                                userName: product.ownerName,
                              ),
                            ),
                          );
                        },
                      ),

                      if (product.location != null &&
                          product.location!.isNotEmpty)
                        _buildInfoRow(
                          Icons.location_on_outlined,
                          'Location',
                          product.location!,
                        ),
                      if (product.tags.isNotEmpty) ...[
                        _buildInfoRow(
                          Icons.label_outlined,
                          'Tags',
                          product.tags.join(', '),
                        ),
                      ],
                      SizedBox(height: 24.h),

                      // Status and Views
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              Icons.visibility_outlined,
                              '${product.viewCount} views',
                            ),
                            _buildStatItem(
                              Icons.people_outline,
                              '${product.interestedUsers.length} interested',
                            ),
                            _buildStatItem(
                              Icons.flag_outlined,
                              '${product.reportedByUserIds.length} reports',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Action Button
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
            ),
          ),
          child: isOwnProduct ? _buildOwnerActions() : _buildVisitorActions(),
        ),
      ],
    );
  }

  Widget _buildImageSection(ProductModel product) {
    return Column(
      children: [
        // Main Image
        GestureDetector(
          onTap: _showImageGallery,
          child: Container(
            width: double.infinity,
            height: 300.h,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              image: product.images.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(product.images[_selectedImageIndex]),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: product.images.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 64.w,
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'No Image',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                            ),
                      ),
                    ],
                  )
                : null,
          ),
        ),

        // Image Thumbnails
        if (product.images.length > 1) ...[
          SizedBox(height: 12.h),
          SizedBox(
            height: 60.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: product.images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                  },
                  child: Container(
                    width: 60.w,
                    height: 60.h,
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: _selectedImageIndex == index
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(product.images[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ],
    );
  }

  Widget _buildOwnerActions() {
    final isTraded = _product?.status == ProductStatus.traded;

    return SizedBox(
      width: double.infinity,
      child: AuthButton(
        text: isTraded ? 'Item Traded (Cannot Edit)' : 'Edit Item',
        onPressed: isTraded
            ? null
            : () {
                if (_product != null) {
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute(
                      builder: (context) => CreateProduct(product: _product!),
                    ),
                  )
                      .then((_) {
                    // Reload product details when returning from edit screen
                    _loadProductDetails();
                  });
                }
              },
      ),
    );
  }

  Widget _buildVisitorActions() {
    final product = _product!;
    final isAvailable = product.status == ProductStatus.available;
    final isSellItem = product.transactionType == TransactionType.sell;

    void handleBuyNow() {
      if (UserModel.isGuest) {
        _showGuestLoginPrompt();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(product: product),
        ),
      );
    }

    return Column(
      children: [
        // Primary action — Buy Now (sell) or Initiate Trade (barter)
        SizedBox(
          width: double.infinity,
          child: isSellItem
              ? AuthButton(
                  text: isAvailable
                      ? 'Buy Now — \$${product.price?.toStringAsFixed(2) ?? '0.00'}'
                      : 'Item Sold',
                  onPressed: isAvailable ? handleBuyNow : null,
                  icon: Icon(
                    isAvailable ? Icons.shopping_bag_outlined : Icons.block,
                    size: 20.w,
                  ),
                )
              : AuthButton(
                  text: isAvailable
                      ? (_pendingTradeCount > 0
                          ? 'Send Counter Offer'
                          : 'Initiate Trade')
                      : 'Not Available for Trade',
                  onPressed: isAvailable ? _initiateTrade : null,
                  icon: Icon(
                    isAvailable ? Icons.swap_horiz : Icons.block,
                    size: 20.w,
                  ),
                ),
        ),
        if (!isAvailable) ...[
          SizedBox(height: 8.h),
          Text(
            isSellItem
                ? 'This item has already been sold'
                : 'This product is ${product.status.displayName.toLowerCase()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
        SizedBox(height: 12.h),
        // Secondary actions row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _contactOwner,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                icon: Icon(Icons.message_outlined, size: 18.w),
                label: Text('Contact'),
              ),
            ),
            SizedBox(width: 12.w),
            OutlinedButton(
              onPressed: _isFavouriteLoading ? null : _toggleFavourite,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                backgroundColor: _isFavourite
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
                side: _isFavourite
                    ? BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      )
                    : null,
              ),
              child: _isFavouriteLoading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isFavourite ? Icons.favorite : Icons.favorite_outline,
                      size: 20.w,
                      color:
                          _isFavourite ? Theme.of(context).primaryColor : null,
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 20.w, color: Theme.of(context).primaryColor),
        SizedBox(height: 4.h),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'like new':
        return Colors.blue;
      case 'good':
        return Colors.orange;
      case 'fair':
        return Colors.amber;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
