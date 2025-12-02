// screens/trade/initiate_trade_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/routes_manager/routes_manager.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/loading_widget.dart';
import '../../firebase/firebase_service.dart';
import '../../features/products/models/product_model.dart';
import '../../features/trade/models/trade_offer.dart';
import '../../features/authentication/models/user_model.dart';
import '../authentication/widgets/auth_button.dart';
import '../authentication/widgets/auth_text_field.dart';

class InitiateTradeScreen extends StatefulWidget {
  final ProductModel targetProduct;

  const InitiateTradeScreen({super.key, required this.targetProduct});

  @override
  State<InitiateTradeScreen> createState() => _InitiateTradeScreenState();
}

class _InitiateTradeScreenState extends State<InitiateTradeScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<ProductModel> _userProducts = [];
  final List<ProductModel> _selectedOfferedProducts = [];
  bool _isLoading = false;
  bool _loadingProducts = true;
  String? _errorMessage;
  TradeType _selectedTradeType = TradeType.itemForItem;

  @override
  void initState() {
    super.initState();
    _loadUserProducts();
  }

  Future<void> _loadUserProducts() async {
    try {
      final user = UserModel.currentUser;
      if (user == null) {
        throw Exception('Please log in to view your products');
      }

      print(
        '=== SCREEN DEBUG: Starting to load products for user ${user.id} ===',
      );

      final products = await FirebaseService.getUserProducts(user.id, context);

      print(
        '=== SCREEN DEBUG: Received ${products.length} products from FirebaseService ===',
      );

      // Additional client-side filtering
      final availableProducts = products
          .where(
            (p) =>
                p.id !=
                widget.targetProduct.id, // Don't allow trading the same product
          )
          .toList();

      print(
        '=== SCREEN DEBUG: ${availableProducts.length} products available for trading ===',
      );

      setState(() {
        _userProducts = availableProducts;
        _loadingProducts = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('=== SCREEN DEBUG: Error in _loadUserProducts: $e ===');
      setState(() {
        _loadingProducts = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Loading Failed',
          message:
              'Failed to load your products: $e\n\nPlease check your internet connection and try again.',
          icon: Icons.error_outline,
        );
      }
    }
  }

  void _toggleProductSelection(ProductModel product) {
    setState(() {
      if (_selectedOfferedProducts.contains(product)) {
        _selectedOfferedProducts.remove(product);
      } else {
        // For single-item trades, allow only one selection
        if (_selectedTradeType != TradeType.multiForSingle) {
          _selectedOfferedProducts.clear();
        }
        _selectedOfferedProducts.add(product);
      }
    });
  }

  bool _canProceedWithTrade() {
    if (_selectedOfferedProducts.isEmpty) return false;

    switch (_selectedTradeType) {
      case TradeType.itemForItem:
        return _selectedOfferedProducts.length == 1;
      case TradeType.multiForSingle:
        return _selectedOfferedProducts.length >= 1;
      case TradeType.serviceForItem:
      case TradeType.serviceForService:
        return true;
    }
  }

  Future<void> _submitTradeOffer() async {
    if (!_canProceedWithTrade()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = UserModel.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final tradeOffer = TradeOffer(
        id: '', // Will be set by Firebase
        fromUserId: user.id,
        fromUserName: user.name,
        toUserId: widget.targetProduct.ownerId,
        toUserName: widget.targetProduct.ownerName,
        offeredProductIds: _selectedOfferedProducts.map((p) => p.id).toList(),
        requestedProductIds: [widget.targetProduct.id],
        message: _messageController.text.trim(),
        status: TradeStatus.pending,
        type: _selectedTradeType,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)), // 7 days expiry
      );

      await FirebaseService.createTradeOffer(tradeOffer);

      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Trade Offered',
          message: 'Your trade offer has been sent successfully!',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Error',
          message: 'Failed to send trade offer: $e',
          icon: Icons.error_outline,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Initiate Trade',
        actions: [
          IconButton(
            onPressed: _loadUserProducts, // Add retry functionality
            icon: Icon(Icons.refresh),
            tooltip: 'Retry',
          ),
          IconButton(
            onPressed: () {
              showInfoDialog(
                context: context,
                title: 'Trade Types',
                message:
                    '• Item for Item: Exchange one item for another\n'
                    '• Multi for Single: Offer multiple items for one valuable item\n'
                    '• Service for Item: Offer a service in exchange for an item\n'
                    '• Service for Service: Exchange services',
                icon: Icons.help_outline,
              );
            },
            icon: Icon(Icons.help_outline),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingProducts) {
      return LoadingOverlay(
        child: Container(),
        isLoading: true,
        loadingMessage: 'Loading your products...',
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return _buildMainContent();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
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
              'Failed to Load Products',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AuthButton(
                  text: 'Try Again',
                  onPressed: _loadUserProducts,
                  isOutlined: true,
                ),
                SizedBox(width: 12.w),
                AuthButton(
                  text: 'Add Product',
                  onPressed: () {
                    // Navigate to add product screen
                    Navigator.of(
                      context,
                    ).pushNamed(RoutesManager.createProduct);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Target Product Card
                _buildProductCard(
                  widget.targetProduct,
                  'You are requesting:',
                  Colors.blue.withOpacity(0.1),
                ),

                SizedBox(height: 24.h),

                // Trade Type Selection
                Text(
                  'Trade Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                _buildTradeTypeSelector(),

                SizedBox(height: 24.h),

                // Your Products to Offer
                Text(
                  'Select items to offer:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),

                if (_userProducts.isEmpty) ...[
                  _buildNoProductsState(),
                ] else ...[
                  _buildProductsGrid(),
                ],

                SizedBox(height: 24.h),

                // Message
                AuthTextField(
                  label: '',
                  controller: _messageController,
                  hint: 'Add a message to the owner (optional)',
                  maxLines: 4,
                  // maxLength: 500,
                ),
              ],
            ),
          ),
        ),

        // Submit Button
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
            ),
          ),
          child: AuthButton(
            text: 'Send Trade Offer',
            onPressed: _canProceedWithTrade() ? _submitTradeOffer : null,
            isLoading: _isLoading,
            icon: Icon(Icons.send, size: 18.w),
          ),
        ),
      ],
    );
  }

  Widget _buildNoProductsState() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64.w,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            'No Products Available for Trade',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'You need to add some products to your inventory before you can trade.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          AuthButton(
            text: 'Add Your First Product',
            onPressed: () {
              Navigator.of(context).pushNamed(RoutesManager.createProduct);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, String title, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              image: product.images.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(product.images.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: product.images.isEmpty
                ? Icon(
                    Icons.image,
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  )
                : null,
          ),

          SizedBox(width: 12.w),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4.h),
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  product.category,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeTypeSelector() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: TradeType.values.map((type) {
        final isSelected = _selectedTradeType == type;
        return FilterChip(
          label: Text(_getTradeTypeDisplayName(type)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedTradeType = type;
              // Clear selection when changing type
              _selectedOfferedProducts.clear();
            });
          },
        );
      }).toList(),
    );
  }

  String _getTradeTypeDisplayName(TradeType type) {
    switch (type) {
      case TradeType.itemForItem:
        return 'Item for Item';
      case TradeType.serviceForItem:
        return 'Service for Item';
      case TradeType.serviceForService:
        return 'Service for Service';
      case TradeType.multiForSingle:
        return 'Multi for Single';
    }
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.8,
      ),
      itemCount: _userProducts.length,
      itemBuilder: (context, index) {
        final product = _userProducts[index];
        final isSelected = _selectedOfferedProducts.contains(product);

        return _buildSelectableProductCard(product, isSelected);
      },
    );
  }

  Widget _buildSelectableProductCard(ProductModel product, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleProductSelection(product),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : Theme.of(context).cardColor,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Image
                Container(
                  height: 100.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(10.r),
                    ),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    image: product.images.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(product.images.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product.images.isEmpty
                      ? Icon(
                          Icons.image,
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.5),
                        )
                      : null,
                ),

                // Product Details
                Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        product.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Selection Indicator
            if (isSelected)
              Positioned(
                top: 8.w,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, size: 16.w, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
