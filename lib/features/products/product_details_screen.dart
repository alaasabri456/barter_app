// features/product_details/product_details_screen.dart
// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/loading_widget.dart';
import '../../firebase/firebase_service.dart';
import '../../features/products/models/product_model.dart';
import '../../features/authentication/models/user_model.dart';
import '../authentication/widgets/auth_button.dart';
import '../chat/chat_screen.dart';
import '../trade/trade_initiation_screen.dart';
import '../create_product/create_product.dart';
import '../profile/public_profile_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

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

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      // Increment view count (fire and forget - don't block loading)
      final userId = UserModel.currentUser?.id ?? '';
      if (userId.isNotEmpty) {
        FirebaseService.incrementProductViewCount(
          widget.productId,
          userId,
        ).catchError((e) {
          print('Failed to increment view count: $e');
        });
      }

      // Load product details
      final product = await FirebaseService.getProductById(
        widget.productId,
        context,
      );
      setState(() {
        _product = product;
        _isLoading = false;
      });

      // Load favorite status
      await _loadFavouriteStatus();
    } catch (e) {
      setState(() {
        _errorLoading = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavouriteStatus() async {
    final userId = UserModel.currentUser?.id;
    if (userId == null) return;

    try {
      final isFav = await FirebaseService.isFavourite(userId, widget.productId);
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

    if (userId == null) {
      print('User not logged in');
      showInfoDialog(
        context: context,
        title: 'Sign in Required',
        message: 'Please sign in to add products to your favorites.',
        icon: Icons.login,
      );
      return;
    }

    print('Setting loading state...');
    setState(() {
      _isFavouriteLoading = true;
    });

    try {
      print('Calling toggleFavourite for product: ${widget.productId}');
      final newStatus = await FirebaseService.toggleFavourite(
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
    if (_product != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InitiateTradeScreen(targetProduct: _product!),
        ),
      );
    }
  }

  void _contactOwner() async {
    final currentUserId = UserModel.currentUser?.id;

    if (currentUserId == null) {
      showInfoDialog(
        context: context,
        title: 'Sign in Required',
        message: 'Please sign in to contact the product owner.',
        icon: Icons.login,
      );
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
    showConfirmationDialog(
      context: context,
      title: 'Report Item',
      message: 'Are you sure you want to report this item?',
      confirmText: 'Report',
      cancelText: 'Cancel',
      icon: Icons.flag_outlined,
    ).then((confirmed) async {
      if (confirmed == true && _product != null) {
        final userId = UserModel.currentUser?.id;
        if (userId == null) return;

        try {
          await FirebaseService.reportProduct(
            productId: _product!.id,
            userId: userId,
          );

          if (mounted) {
            showInfoDialog(
              context: context,
              title: 'Report Submitted',
              message:
                  'Thank you for reporting. We will review this item shortly.',
              icon: Icons.check_circle,
              iconColor: Colors.green,
            );

            // Refresh product to show updated report count
            _loadProductDetails();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to report: $e')));
          }
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
        child: _errorLoading
            ? _buildErrorState()
            : _product == null
            ? _buildEmptyState()
            : _buildProductDetails(isOwnProduct),
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
                              style: Theme.of(context).textTheme.headlineSmall
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
                                    color:
                                        product.status ==
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
                      SizedBox(height: 8.h),
                      Row(
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
                          SizedBox(width: 8.w),
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
                      SizedBox(height: 16.h),

                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium
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
                        style: Theme.of(context).textTheme.titleMedium
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
                          builder: (context) =>
                              CreateProduct(product: _product!),
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

    return Column(
      children: [
        // Primary action - Initiate Trade
        SizedBox(
          width: double.infinity,
          child: AuthButton(
            text: isAvailable ? 'Initiate Trade' : 'Not Available for Trade',
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
            'This product is ${product.status.displayName.toLowerCase()}',
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
                      color: _isFavourite
                          ? Theme.of(context).primaryColor
                          : null,
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
