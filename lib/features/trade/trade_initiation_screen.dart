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
  List<ProductModel> _targetUserProducts = []; // NEW
  List<ProductModel> _selectedRequestedProducts = []; // NEW

  @override
  void initState() {
    super.initState();
    _selectedRequestedProducts = [
      widget.targetProduct,
    ]; // Initialize with target
    _loadUserProducts();
    _loadTargetUserProducts(); // Load target inventory
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
                    widget
                        .targetProduct
                        .id && // Don't allow trading the same product
                p.status.name.toLowerCase() !=
                    'traded' && // Don't allow traded products
                p.status.name.toLowerCase() !=
                    'accepted', // Don't allow accepted products
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

  Future<void> _loadTargetUserProducts() async {
    try {
      final products = await FirebaseService.getUserProducts(
        widget.targetProduct.ownerId,
        context,
      );
      if (mounted) {
        setState(() {
          _targetUserProducts = products
              .where(
                (p) => p.isAvailable && p.status == ProductStatus.available,
              )
              .toList();
        });
      }
    } catch (e) {
      print('Error loading target inventory: $e');
    }
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

      // Check for duplicate trade
      final isDuplicate = await FirebaseService.isDuplicateTrade(
        userId: user.id,
        targetProductId: widget.targetProduct.id,
        offeredProductIds: _selectedOfferedProducts.map((p) => p.id).toList(),
      );

      if (isDuplicate) {
        if (mounted) {
          await showInfoDialog(
            context: context,
            title: 'Duplicate Offer',
            message:
                'You have already sent this exact trade offer for this item. Please wait for a response or offer different items.',
            icon: Icons.copy,
            iconColor: Colors.orange,
          );
        }
        return;
      }

      final tradeOffer = TradeOffer(
        id: '', // Will be set by Firebase
        fromUserId: user.id,
        fromUserName: user.name,
        toUserId: widget.targetProduct.ownerId,
        toUserName: widget.targetProduct.ownerName,
        offeredProductIds: _selectedOfferedProducts.map((p) => p.id).toList(),
        requestedProductIds: _selectedRequestedProducts
            .map((p) => p.id)
            .toList(),
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
        loadingMessage: 'Loading your items...',
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
              'Failed to Load Items',
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
                  text: 'Add Item',
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
        // 1. Visual Swap Stage (Fixed at top)
        _buildSwapStage(),

        // 2. Scrollable Inventory Selection
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Items',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Trade Type Chip
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<TradeType>(
                            value: _selectedTradeType,
                            isDense: true,
                            onChanged: (TradeType? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedTradeType = newValue;
                                  _selectedOfferedProducts.clear();
                                });
                              }
                            },
                            items: TradeType.values
                                .map<DropdownMenuItem<TradeType>>((
                                  TradeType value,
                                ) {
                                  return DropdownMenuItem<TradeType>(
                                    value: value,
                                    child: Text(
                                      _getTradeTypeDisplayName(value),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: _userProducts.isEmpty
                      ? _buildNoProductsState()
                      : _buildProductsGrid(),
                ),
              ],
            ),
          ),
        ),

        // 3. Action Bar
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedOfferedProducts.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: AuthTextField(
                    label: '',
                    controller: _messageController,
                    hint: 'Add a message (optional)...',
                    maxLines: 2,
                  ),
                ),
              AuthButton(
                text: _canProceedWithTrade()
                    ? 'Send Offer (${_selectedOfferedProducts.length} items)'
                    : 'Select Items to Offer',
                onPressed: _canProceedWithTrade() ? _submitTradeOffer : null,
                isLoading: _isLoading,
                icon: Icon(Icons.send_rounded, size: 20.w),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwapStage() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Row(
        children: [
          // Left: You Get (Target Product)
          Expanded(
            child: Column(
              children: [
                Text(
                  'YOU GET',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 12.h),
                Stack(
                  alignment: Alignment.topRight,
                  clipBehavior: Clip.none,
                  children: [
                    _buildStageCard(
                      image: _selectedRequestedProducts
                          .firstOrNull
                          ?.images
                          .firstOrNull,
                      title: _selectedRequestedProducts.length == 1
                          ? _selectedRequestedProducts.first.title
                          : '${_selectedRequestedProducts.length} Items',
                      owner: widget.targetProduct.ownerName,
                      isTarget: true,
                      onTap: _showTargetInventorySheet,
                    ),
                    Positioned(
                      top: -6.h,
                      right: -6.w,
                      child: GestureDetector(
                        onTap: _showTargetInventorySheet,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16.w,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Center: Swap Icon
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Column(
              children: [
                SizedBox(height: 24.h), // Offset for title
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        const Color(0xFFC026D3), // Apps secondary color/Purple
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                    size: 28.w,
                  ),
                ),
              ],
            ),
          ),

          // Right: You Offer (Selected Products)
          Expanded(
            child: Column(
              children: [
                Text(
                  'YOU OFFER',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 12.h),
                _selectedOfferedProducts.isEmpty
                    ? _buildEmptyOfferPlaceholder()
                    : _selectedOfferedProducts.length == 1
                    ? _buildStageCard(
                        image:
                            _selectedOfferedProducts.first.images.firstOrNull,
                        title: _selectedOfferedProducts.first.title,
                        owner: 'You',
                        onTap: () => _toggleProductSelection(
                          _selectedOfferedProducts.first,
                        ),
                      )
                    : _buildMultiOfferStack(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTargetInventorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              children: [
                SizedBox(height: 12.h),
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(
                    'What else do you want from ${widget.targetProduct.ownerName}?',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _targetUserProducts.isEmpty
                      ? Center(child: Text("No other items available"))
                      : GridView.builder(
                          controller: controller,
                          padding: EdgeInsets.all(16.w),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12.w,
                                mainAxisSpacing: 12.h,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: _targetUserProducts.length,
                          itemBuilder: (context, index) {
                            final product = _targetUserProducts[index];
                            final isSelected = _selectedRequestedProducts.any(
                              (p) => p.id == product.id,
                            );
                            return _buildSelectableProductCard(
                              product,
                              isSelected,
                              onTap: () {
                                _toggleRequestedProductSelection(product);
                                setModalState(() {});
                              },
                            );
                          },
                        ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: AuthButton(
                    text:
                        'Done (${_selectedRequestedProducts.length} selected)',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleRequestedProductSelection(ProductModel product) {
    setState(() {
      if (_selectedRequestedProducts.any((p) => p.id == product.id)) {
        if (_selectedRequestedProducts.length > 1) {
          _selectedRequestedProducts.removeWhere((p) => p.id == product.id);
        }
      } else {
        _selectedRequestedProducts.add(product);
      }
    });
  }

  Widget _buildStageCard({
    required String? image,
    required String title,
    required String owner,
    bool isTarget = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: isTarget
              ? Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                child: image != null
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      owner,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildEmptyOfferPlaceholder() {
    return Container(
      height: 140.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.grey[300]!,
          style: BorderStyle.solid,
          width: 1,
        ), // Dashed border simulated or just solid light grey
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, color: Colors.grey[400], size: 32.w),
          SizedBox(height: 8.h),
          Text(
            'Select Items',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiOfferStack() {
    // Show a stack effect or just the count for multiple items
    final first = _selectedOfferedProducts.first;
    return Container(
      height: 140.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background cards for stack effect
          if (_selectedOfferedProducts.length > 1)
            Positioned(
              top: 4,
              child: Container(
                height: 130.h,
                width: 100.w, // Narrower
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
              ),
            ),

          // Main Card
          _buildStageCard(
            image: first.images.firstOrNull,
            title: '${_selectedOfferedProducts.length} Items',
            owner: 'Tap to edit',
            onTap: () {
              // Optional: Show list of selected to remove
            },
          ),

          // Count Badge
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                '${_selectedOfferedProducts.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProductsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48.w, color: Colors.grey[300]),
          SizedBox(height: 12.h),
          Text(
            'Inventory Empty',
            style: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(RoutesManager.createProduct),
            child: Text('Add Item'),
          ),
        ],
      ),
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
      padding: EdgeInsets.all(20.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 columns for compact inventory
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

  Widget _buildSelectableProductCard(
    ProductModel product,
    bool isSelected, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () => _toggleProductSelection(product),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : Colors.white,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.images.isNotEmpty
                        ? Image.network(product.images.first, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey[100],
                            child: Icon(
                              Icons.image,
                              size: 20,
                              color: Colors.grey[300],
                            ),
                          ),

                    if (isSelected)
                      Container(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Text(
                product.title,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
} // End of State class
