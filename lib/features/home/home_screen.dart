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
  List<String> _allCategories = []; // Combined default + custom categories
  bool _categoriesLoaded = false;

  // Track favorite states for each product
  Map<String, bool> _favouriteStates = {};
  Map<String, bool> _favouriteLoading = {};

  @override
  void initState() {
    super.initState();
    _productsFuture = FirebaseService.getProductsFromFireStore(context);
    _loadFavouriteStates();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      // Get default categories
      final defaultCategories = ProductCategory.values
          .map((c) => c.displayName)
          .toList();

      // Get approved custom categories
      final customCategories = await FirebaseService.getApprovedCategories();
      final customNames = customCategories.map((c) => c.name).toList();

      if (mounted) {
        setState(() {
          _allCategories = [...defaultCategories, ...customNames];
          _categoriesLoaded = true;
        });
      }
    } catch (e) {
      // Fallback to default categories only
      if (mounted) {
        setState(() {
          _allCategories = ProductCategory.values
              .map((c) => c.displayName)
              .toList();
          _categoriesLoaded = true;
        });
      }
    }
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

    // Also reload categories in case new ones were approved
    _loadCategories();

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
        title: '',
        titleWidget: Image.asset(
          'assets/images/logo_transparent_v2.png',
          height: 120.h,
          fit: BoxFit.contain,
        ),
        height: 80,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to notifications screen
            },
            icon: Icon(Icons.notifications_outlined, size: 28.sp),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              accountName: Text(
                user?.name ?? 'Guest User',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
              ),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (user?.name ?? 'G').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 24.sp,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),

            ListTile(
              leading: Icon(Icons.chat_bubble_outline),
              title: Text('Chat'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushNamed(context, RoutesManager.chatList);
              },
            ),
            ListTile(
              leading: Icon(
                themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
              ),
              title: Text(themeProvider.isDark ? 'Light Mode' : 'Dark Mode'),
              onTap: () {
                themeProvider.changeAppTheme(
                  themeProvider.isDark ? ThemeMode.light : ThemeMode.dark,
                );
              },
            ),
          ],
        ),
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
                        'Failed to load items:\n$errorText',
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
                // Search Bar (formerly with Welcome Text)
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar
                        SearchTextField(
                          hint: 'Search items to barter...',
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

                // Categories Filter
                SliverToBoxAdapter(
                  child: Container(
                    height: 50.h,
                    margin: EdgeInsets.symmetric(vertical: 12.h),
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      scrollDirection: Axis.horizontal,
                      itemCount: _allCategories.length + 1, // +1 for "All"
                      separatorBuilder: (context, index) =>
                          SizedBox(width: 8.w),
                      itemBuilder: (context, index) {
                        final isAllOption = index == 0;
                        final category = isAllOption
                            ? 'All'
                            : _allCategories[index - 1];
                        final isSelected = isAllOption
                            ? _selectedCategory == null
                            : _selectedCategory == category;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isAllOption) {
                                _selectedCategory = null;
                              } else {
                                // Toggle selection
                                if (_selectedCategory == category) {
                                  _selectedCategory = null;
                                } else {
                                  _selectedCategory = category;
                                }
                              }
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            child: Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[800],
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
                          'Recent Items',
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
                                ? 'No items yet.'
                                : 'No items match your search.',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Products Grid
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                        childAspectRatio: 0.8,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = filtered[index];
                        return _buildProductCard(product);
                      }, childCount: filtered.length),
                    ),
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
      imageHeight: 150.h,
      onTap: () {
        Navigator.of(
          context,
        ).pushNamed(RoutesManager.productDetails, arguments: product.id);
      },
    );
  }
}
