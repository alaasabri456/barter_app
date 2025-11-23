import 'package:barter/firebase/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/routes_manager/routes_manager.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../provider/theme_provider.dart';
import '../authentication/widgets/auth_text_field.dart';
import '../trade/trade_initiation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Future<List<ProductModel>>? _productsFuture;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _productsFuture = FirebaseService.getProductsFromFireStore(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
    });
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isRefreshing = true;
      // reassign the future so the FutureBuilder re-runs
      _productsFuture = FirebaseService.getProductsFromFireStore(context);
    });

    try {
      // Await the current fetch so RefreshIndicator spinner shows until complete
      await _productsFuture;
    } catch (_) {
      // ignore — error will be handled by FutureBuilder
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  List<ProductModel> _applySearchFilter(List<ProductModel> products) {
    if (_searchQuery.isEmpty) return products;
    return products.where((p) {
      final title = p.title.toLowerCase();
      final desc = p.description.toLowerCase();
      final category = p.category.toLowerCase();
      return title.contains(_searchQuery) ||
          desc.contains(_searchQuery) ||
          category.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = UserModel.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Barter',
        actions: [
          IconButton(
            onPressed: () {
              themeProvider.changeAppTheme(
                themeProvider.isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
            icon: Icon(themeProvider.isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: FutureBuilder<List<ProductModel>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting && !_isRefreshing) {
              return Center(child: CircularProgressIndicator());
            }

            // Error state
            if (snapshot.hasError) {
              final errorText = snapshot.error?.toString() ?? 'Unknown error';
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Text(
                        'Failed to load products:\n$errorText',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              );
            }

            final products = snapshot.data ?? [];

            // Apply local search filtering
            final filtered = _applySearchFilter(products);

            return CustomScrollView(
              slivers: [
                // Welcome + Search
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).textTheme.titleLarge?.color?.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          user?.name ?? 'User',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Search bar
                        SearchTextField(
                          hint: 'Search products to barter...',
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          onClear: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Categories horizontal list (static for now)
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 12.h),
                        Text(
                          'Categories',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          height: 110.h,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                            children: [
                              _buildCategoryCard('Electronics', Icons.phone_android, Colors.blue),
                              _buildCategoryCard('Clothing', Icons.checkroom, Colors.purple),
                              _buildCategoryCard('Books', Icons.menu_book, Colors.brown),
                              _buildCategoryCard('Sports', Icons.sports_football, Colors.green),
                              _buildCategoryCard('Home', Icons.home, Colors.orange),
                              _buildCategoryCard('Others', Icons.more_horiz, Colors.grey),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                ),

                // Recent products header
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Products',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            // navigate to full products screen if exists
                          },
                          child: Text('See All'),
                        ),
                      ],
                    ),
                  ),
                ),

                // If no products (after filtering)
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64.w, color: Colors.grey),
                          SizedBox(height: 16.h),
                          Text(
                            products.isEmpty ? 'No products yet.' : 'No products match your search.',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                // Products list
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final product = filtered[index];
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                          child: _buildProductCard(product),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),

                // Bottom padding
                SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    return Container(
      width: 90.w,
      margin: EdgeInsets.only(right: 12.w),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: InkWell(
          onTap: () {
            // Navigate to category products
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(8.w), // Reduced padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Add this to minimize size
              children: [
                Container(
                  padding: EdgeInsets.all(8.w), // Reduced padding
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20.w, // Reduced icon size
                  ),
                ),
                SizedBox(height: 4.h), // Reduced spacing
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 10.sp, // Explicitly set smaller font size
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // Allow 2 lines instead of 1
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildProductCard(ProductModel product) {
    final firstImage = product.images.isNotEmpty ? product.images.first : null;
    final createdAgo = _formatDate(product.createdAt);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
              RoutesManager.productDetails,
              arguments: product.id,);
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8.r),
                  image: firstImage != null
                      ? DecorationImage(image: NetworkImage(firstImage), fit: BoxFit.cover)
                      : null,
                ),
                child: firstImage == null
                    ? Icon(Icons.image, color: Theme.of(context).primaryColor.withOpacity(0.5), size: 32.w)
                    : null,
              ),

              SizedBox(width: 12.w),

              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      product.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 6.h),

                    // Short description
                    Text(
                      product.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 8.h),

                    // Category & condition & meta
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            product.category,
                            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            product.condition,
                            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500, color: Colors.green),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          createdAgo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.sp),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Favorite / actions column - UPDATED WITH TRADE BUTTON
              Column(
                children: [
                  // Trade button - only show if it's not the user's own product
                  if (UserModel.currentUser?.id != product.ownerId) ...[
                    IconButton(
                      onPressed: () {
                        // Navigate to initiate trade screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => InitiateTradeScreen(
                              targetProduct: product,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.swap_horiz, color: Theme.of(context).primaryColor),
                      tooltip: 'Make Trade Offer',
                    ),
                  ],
                  // Favorite button
                  IconButton(
                    onPressed: () {
                      // Toggle favorite logic (update UI & backend as needed)
                    },
                    icon: Icon(Icons.favorite_border, color: Theme.of(context).iconTheme.color?.withOpacity(0.6)),
                    tooltip: 'Add to favorites',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays >= 7) {
      // show date if older than a week
      return '${dt.day}/${dt.month}/${dt.year}';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}d';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
