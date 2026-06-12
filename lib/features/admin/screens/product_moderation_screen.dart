import 'package:barter/features/products/models/product_model.dart';
import 'package:provider/provider.dart';
import '../../admin/viewmodels/admin_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductModerationScreen extends StatefulWidget {
  const ProductModerationScreen({super.key});

  @override
  State<ProductModerationScreen> createState() =>
      _ProductModerationScreenState();
}

class _ProductModerationScreenState extends State<ProductModerationScreen> {
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  ProductStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await context.read<AdminViewModel>().getAllProductsAdmin();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterProducts(String query) {
    setState(() {
      var filtered = _products;

      // Filter by search query
      if (query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        filtered = filtered.where((product) {
          return product.title.toLowerCase().contains(lowerQuery) ||
              product.description.toLowerCase().contains(lowerQuery) ||
              product.ownerName.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      // Filter by status
      if (_selectedStatus != null) {
        filtered = filtered.where((p) => p.status == _selectedStatus).toList();
      }

      _filteredProducts = filtered;
    });
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.title}"?\n\n'
          'This will:\n'
          '• Remove the product permanently\n'
          '• Reject all pending trades for this product\n\n'
          'THIS ACTION CANNOT BE UNDONE!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<AdminViewModel>().deleteProductById(product.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
        _loadProducts();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Moderation'),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                  ),
                  onChanged: (value) => _filterProducts(value),
                ),
                SizedBox(height: 12.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      SizedBox(width: 8.w),
                      ...ProductStatus.values.map((status) {
                        return Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: _buildFilterChip(
                            status.toString().split('.').last.toUpperCase(),
                            status,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64.sp,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16.h),
                            Text('Error: $_error'),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: _loadProducts,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredProducts.isEmpty
                        ? Center(
                            child: Text(
                              'No products found',
                              style: TextStyle(
                                  fontSize: 16.sp, color: Colors.grey),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadProducts,
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return _buildProductCard(product);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ProductStatus? status) {
    final isSelected = _selectedStatus == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
          _filterProducts(_searchController.text);
        });
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: ExpansionTile(
        leading: product.images.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  product.images.first,
                  width: 50.w,
                  height: 50.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50.w,
                      height: 50.w,
                      color: Colors.grey,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              )
            : Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: const Icon(Icons.inventory_2),
              ),
        title: Text(
          product.title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By: ${product.ownerName}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      product.status,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    product.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: _getStatusColor(product.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                if (!product.isAvailable)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'UNAVAILABLE',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(product.description, style: TextStyle(fontSize: 13.sp)),
                SizedBox(height: 12.h),
                Text(
                  'Condition: ${product.condition}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                Text(
                  'Category: ${product.category}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                Text(
                  'Product ID: ${product.id}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                Text(
                  'Owner ID: ${product.ownerId}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: () => _deleteProduct(product),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.available:
        return Colors.green;
      case ProductStatus.reserved:
        return Colors.orange;
      case ProductStatus.traded:
        return Colors.blue;
      case ProductStatus.unavailable:
        return Colors.red;
    }
  }
}
