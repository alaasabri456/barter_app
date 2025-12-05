import 'package:barter/firebase/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/routes_manager/routes_manager.dart';
import '../../core/widgets/custom_app_bar.dart';

import '../../features/products/models/product_model.dart';
import '../../features/authentication/models/user_model.dart';
import '../../core/theme/theme_provider.dart';
import '../authentication/widgets/auth_text_field.dart';

import '../products/widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  Future<List<ProductModel>>? _productsFuture;
  bool _isRefreshing = false;

  // Track favorite states for each product
  Map<String, bool> _favouriteStates = {};
  Map<String, bool> _favouriteLoading = {};

  @override
  void initState() {
    super.initState();
    _productsFuture = FirebaseService.getProductsFromFireStore(context);
    _loadFavouriteStates();
  }

  Future<void> _loadFavouriteStates() async {
    final userId = UserModel.currentUser?.id;
    if (userId == null) return;

    try {
      final products = await _productsFuture;
      if (products != null) {
        for (var product in products) {
          final isFav = await FirebaseService.isFavourite(userId, product.id);
          if (mounted) {
            setState(() {
              _favouriteStates[product.id] = isFav;
            });
          }
        }
      }
    } catch (e) {
      // Silently fail - not critical
    }
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
    var filtered = products;

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered
          .where(
            (p) => p.category.toLowerCase() == _selectedCategory!.toLowerCase(),
          )
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isEmpty) return filtered;

    return filtered.where((p) {
      final title = p.title.toLowerCase();
      final desc = p.description.toLowerCase();
      final category = p.category.toLowerCase();
      return title.contains(_searchQuery) ||
          desc.contains(_searchQuery) ||
          category.contains(_searchQuery);
    }).toList();
  }

  Future<void> _toggleFavourite(ProductModel product) async {
    final userId = UserModel.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add favorites')),
      );
      return;
    }

    // Optimistic update
    setState(() {
      _favouriteLoading[product.id] = true;
    });

    try {
      final newStatus = await FirebaseService.toggleFavourite(
        userId,
        product.id,
      );

      if (mounted) {
        setState(() {
          _favouriteStates[product.id] = newStatus;
          _favouriteLoading[product.id] = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Added to favorites ❤️' : 'Removed from favorites',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _favouriteLoading[product.id] = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            icon: Icon(
              themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: FutureBuilder<List<ProductModel>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting &&
                !_isRefreshing) {
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.color?.withOpacity(0.7),
                              ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          user?.name ?? 'User',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          height: 110.h,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(
                              vertical: 8.h,
                              horizontal: 4.w,
                            ),
                            children: [
                              _buildCategoryCard(
                                'Electronics',
                                Icons.phone_android,
                                Colors.blue,
                              ),
                              _buildCategoryCard(
                                'Clothing',
                                Icons.checkroom,
                                Colors.purple,
                              ),
                              _buildCategoryCard(
                                'Books',
                                Icons.menu_book,
                                Colors.brown,
                              ),
                              _buildCategoryCard(
                                'Sports',
                                Icons.sports_football,
                                Colors.green,
                              ),
                              _buildCategoryCard(
                                'Home',
                                Icons.home,
                                Colors.orange,
                              ),
                              _buildCategoryCard(
                                'Others',
                                Icons.more_horiz,
                                Colors.grey,
                              ),
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 40.h,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64.w,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            products.isEmpty
                                ? 'No products yet.'
                                : 'No products match your search.',
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
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = filtered[index];
                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 8.h,
                        ),
                        child: _buildProductCard(product),
                      );
                    }, childCount: filtered.length),
                  ),

                // Bottom padding
                SliverToBoxAdapter(child: SizedBox(height: 110.h)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    final isSelected = _selectedCategory == title;

    return Container(
      width: 90.w,
      margin: EdgeInsets.only(right: 12.w),
      child: Card(
        elevation: isSelected ? 4 : 2,
        color: isSelected ? Theme.of(context).primaryColor : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: isSelected
              ? BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              if (_selectedCategory == title) {
                _selectedCategory = null; // Deselect if already selected
              } else {
                _selectedCategory = title;
              }
            });
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : color,
                    size: 20.w,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 10.sp,
                    color: isSelected ? Colors.white : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
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
    return ProductCard(
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
      isFavorite: _favouriteStates[product.id] ?? false,
      onFavoriteToggle: () => _toggleFavourite(product),
      onTap: () {
        Navigator.of(
          context,
        ).pushNamed(RoutesManager.productDetails, arguments: product.id);
      },
    );
  }
}
