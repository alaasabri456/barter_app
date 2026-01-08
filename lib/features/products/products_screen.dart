// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/loading_widget.dart';
import '../../features/authentication/models/user_model.dart';
import '../../features/products/models/product_model.dart';
import '../../firebase/firebase_service.dart';
import '../authentication/widgets/auth_text_field.dart';
import 'widgets/product_card.dart';
import '../create_product/create_product.dart';
import 'product_details_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedCondition = 'All';
  List<ProductModel> _products = [];
  String? _errorMessage;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Clothing',
    'Books',
    'Sports',
    'Home',
    'Others',
  ];

  final List<String> _conditions = [
    'All',
    'New',
    'Like New',
    'Good',
    'Fair',
    'Poor',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final user = UserModel.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Please log in to view your items';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await FirebaseService.getUserProducts(user.id, context);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load items: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onSearchClear() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          SizedBox(height: 20.h),

          Text(
            'Filter Products',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 24.h),

          // Category filter
          Text(
            'Category',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          SizedBox(height: 12.h),

          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              );
            }).toList(),
          ),

          SizedBox(height: 24.h),

          // Condition filter
          Text(
            'Condition',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          SizedBox(height: 12.h),

          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _conditions.map((condition) {
              final isSelected = _selectedCondition == condition;
              return FilterChip(
                label: Text(condition),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCondition = condition;
                  });
                },
              );
            }).toList(),
          ),

          SizedBox(height: 32.h),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'All';
                      _selectedCondition = 'All';
                    });
                  },
                  child: Text('Clear'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {}); // Trigger rebuild with new filters
                  },
                  child: Text('Apply'),
                ),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Products',
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: EdgeInsets.all(16.w),
            child: SearchTextField(
              hint: 'Search my products...',
              controller: _searchController,
              onChanged: _onSearchChanged,
              onClear: _onSearchClear,
            ),
          ),

          // Tab bar
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Available'),
                Tab(text: 'Traded'),
                Tab(text: 'All'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: LoadingOverlay(
              isLoading: _isLoading,
              loadingMessage: 'Loading products...',
              child: _errorMessage != null
                  ? _buildErrorState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProductsList(ProductStatus.available),
                        _buildProductsList(ProductStatus.traded),
                        _buildProductsList(null), // All products
                      ],
                    ),
            ),
          ),
        ],
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
            'Error Loading Products',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              _errorMessage ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(onPressed: _loadProducts, child: Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildProductsList(ProductStatus? statusFilter) {
    // Filter products based on current tab and search/filter criteria
    List<ProductModel> filteredProducts = _products.where((product) {
      bool matchesFilter = true;

      // Status filter
      if (statusFilter != null) {
        matchesFilter = product.status == statusFilter;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        matchesFilter = matchesFilter &&
            (product.title.toLowerCase().contains(query) ||
                product.description.toLowerCase().contains(query));
      }

      // Category filter
      if (_selectedCategory != 'All') {
        matchesFilter = matchesFilter &&
            product.category.toLowerCase() == _selectedCategory.toLowerCase();
      }

      // Condition filter
      if (_selectedCondition != 'All') {
        matchesFilter = matchesFilter &&
            product.condition.toLowerCase() == _selectedCondition.toLowerCase();
      }

      return matchesFilter;
    }).toList();

    if (filteredProducts.isEmpty) {
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
              _products.isEmpty ? 'No products yet' : 'No products found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.titleMedium?.color?.withOpacity(0.5),
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              _products.isEmpty
                  ? 'Start by adding your first product'
                  : 'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: ProductCard(
              title: product.title,
              description: product.description,
              category: product.category,
              condition: product.condition,
              status: product.status.name,
              viewCount: product.viewCount,
              interestedCount: product.interestedUsers.length,
              createdAt: product.createdAt,
              imageUrl: product.images.isNotEmpty ? product.images.first : null,
              location: product.location,
              type: product.type.name,
              availability: product.availability,
              onTap: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsScreen(productId: product.id),
                      ),
                    )
                    .then((_) => _loadProducts());
              },
              onEdit: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => CreateProduct(product: product),
                      ),
                    )
                    .then((_) => _loadProducts());
              },
              onDelete: () async {
                // Show delete confirmation
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete Product'),
                    content: Text(
                      'Are you sure you want to delete "${product.title}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    // Check if item is in pending trade
                    final isInTrade =
                        await FirebaseService.isProductInPendingTrade(
                      product.id,
                    );

                    if (isInTrade && mounted) {
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Delete Blocked'),
                          content: Text(
                            'This item is part of a pending trade request. Please cancel or complete the trade before deleting.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    await FirebaseService.deleteProduct(product.id);
                    _loadProducts();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Product deleted successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }
}
