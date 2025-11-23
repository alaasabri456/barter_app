import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/user_model.dart';
import '../authentication/widgets/auth_text_field.dart';
import 'widgets/product_card.dart';

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

  final List<String> _categories = [
    'All',
    'Electronics',
    'Clothing',
    'Books',
    'Sports',
    'Home',
    'Others'
  ];

  final List<String> _conditions = [
    'All',
    'New',
    'Like New',
    'Good',
    'Fair',
    'Poor'
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
    setState(() {
      _isLoading = true;
    });

    // Simulate loading products
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 24.h),

          // Category filter
          Text(
            'Category',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
                    _loadProducts();
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
    final user = UserModel.currentUser;

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
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductsList('available'),
                  _buildProductsList('traded'),
                  _buildProductsList('all'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(String filter) {
    // Mock products data
    final List<Map<String, dynamic>> products = List.generate(
      10,
          (index) => {
        'id': 'product_$index',
        'title': 'Sample Product ${index + 1}',
        'description': 'This is a detailed description of the sample product ${index + 1}.',
        'category': _categories[(index % (_categories.length - 1)) + 1],
        'condition': _conditions[(index % (_conditions.length - 1)) + 1],
        'status': index % 3 == 0 ? 'traded' : 'available',
        'imageUrl': null,
        'createdAt': DateTime.now().subtract(Duration(days: index)),
        'viewCount': (index + 1) * 10,
        'interestedUsers': List.generate((index % 5), (i) => 'user_$i'),
      },
    );

    // Filter products based on current tab
    List<Map<String, dynamic>> filteredProducts = products.where((product) {
      bool matchesFilter = true;

      if (filter == 'available') {
        matchesFilter = product['status'] == 'available';
      } else if (filter == 'traded') {
        matchesFilter = product['status'] == 'traded';
      }

      if (_searchQuery.isNotEmpty) {
        matchesFilter = matchesFilter &&
            product['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      }

      if (_selectedCategory != 'All') {
        matchesFilter = matchesFilter && product['category'] == _selectedCategory;
      }

      if (_selectedCondition != 'All') {
        matchesFilter = matchesFilter && product['condition'] == _selectedCondition;
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
              'No products found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).textTheme.titleMedium?.color?.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
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
          return ProductCard(
            title: product['title'],
            description: product['description'],
            category: product['category'],
            condition: product['condition'],
            status: product['status'],
            viewCount: product['viewCount'],
            interestedCount: product['interestedUsers'].length,
            createdAt: product['createdAt'],
            onTap: () {
              // Navigate to product details
            },
            onEdit: () {
              // Navigate to edit product
            },
            onDelete: () {
              // Show delete confirmation
            },
          );
        },
      ),
    );
  }
}