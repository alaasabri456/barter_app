// features/product_details/product_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/routes_manager/routes_manager.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/loading_widget.dart';
import '../../firebase/firebase_service.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../authentication/widgets/auth_button.dart';
import '../trade/trade_initiation_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      // You'll need to implement getProductById in FirebaseService
      final product = await FirebaseService.getProductById(widget.productId,context);
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorLoading = true;
        _isLoading = false;
      });
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
                  image: NetworkImage(_product!.images[_selectedImageIndex]),
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

  void _contactOwner() {
    // Implement contact functionality (email, chat, etc.)
    showInfoDialog(
      context: context,
      title: 'Contact Owner',
      message: 'Contact feature coming soon!\n\n'
          'Owner: ${_product?.ownerName}\n'
          'You can initiate a trade to start communication.',
      icon: Icons.message,
    );
  }

  void _reportProduct() {
    showConfirmationDialog(
      context: context,
      title: 'Report Product',
      message: 'Are you sure you want to report this product?',
      confirmText: 'Report',
      cancelText: 'Cancel',
      icon: Icons.flag_outlined,
    ).then((confirmed) {
      if (confirmed == true) {
        // Implement report functionality
        showInfoDialog(
          context: context,
          title: 'Report Submitted',
          message: 'Thank you for reporting. We will review this product shortly.',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      }
    });
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProduct = _product?.ownerId == UserModel.currentUser?.id;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Product Details',
        actions: [
          IconButton(
            onPressed: _reportProduct,
            icon: Icon(Icons.flag_outlined),
            tooltip: 'Report Product',
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
                      Text(
                        product.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
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
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: _getConditionColor(product.condition).withOpacity(0.1),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Product Details
                      Text(
                        'Product Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildInfoRow(Icons.person_outline, 'Owner', product.ownerName),
                      _buildInfoRow(Icons.category_outlined, 'Category', product.category),
                      _buildInfoRow(Icons.construction_outlined, 'Condition', product.condition),
                      _buildInfoRow(Icons.calendar_today_outlined, 'Listed', _formatDate(product.createdAt)),
                      if (product.location != null && product.location!.isNotEmpty)
                        _buildInfoRow(Icons.location_on_outlined, 'Location', product.location!),
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
                            _buildStatItem(Icons.visibility_outlined, '${product.viewCount} views'),
                            _buildStatItem(Icons.people_outline, '${product.interestedUsers.length} interested'),
                            _buildStatItem(Icons.inventory_2_outlined, product.status.displayName),
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
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: isOwnProduct
              ? _buildOwnerActions()
              : _buildVisitorActions(),
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
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
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
    return Row(
      children: [
        Expanded(
          child: AuthButton(
            text: 'Edit Product',
            onPressed: () {
              // Navigate to edit product screen
              showInfoDialog(
                context: context,
                title: 'Edit Product',
                message: 'Edit feature coming soon!',
                icon: Icons.edit_outlined,
              );
            },
            isOutlined: true,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: AuthButton(
            text: 'Manage Trades',
            onPressed: () {
              // Navigate to trade management
              Navigator.of(context).pushNamed(RoutesManager.tradeManagement);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVisitorActions() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AuthButton(
            text: 'Initiate Trade',
            onPressed: _initiateTrade,
            icon: Icon(Icons.swap_horiz, size: 18.w),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 1,
          child: OutlinedButton(
            onPressed: _contactOwner,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
            ),
            child: Icon(Icons.message_outlined),
          ),
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}