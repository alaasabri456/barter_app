// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/resources/colors_manager.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'package:provider/provider.dart';
import '../favourites/viewmodels/favourites_viewmodel.dart';
import '../../features/authentication/models/user_model.dart';
import '../../features/products/models/product_model.dart';
import '../../core/routes_manager/routes_manager.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  List<ProductModel>? _favouriteProducts;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavourites();
    });
  }

  Future<void> _loadFavourites() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = UserModel.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final products = await context.read<FavouritesViewModel>().getFavouriteProducts(
        userId,
      );

      setState(() {
        _favouriteProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromFavourites(ProductModel product) async {
    try {
      final userId = UserModel.currentUser?.id;
      if (userId == null) return;

      // Optimistic update
      setState(() {
        _favouriteProducts?.removeWhere((p) => p.id == product.id);
      });

      await context.read<FavouritesViewModel>().toggleFavourite(userId, product.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.title} removed from favorites'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      _loadFavourites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove from favorites'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites'), centerTitle: true),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _favouriteProducts == null || _favouriteProducts!.isEmpty
                  ? _buildEmptyState()
                  : _buildFavouritesList(),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: 5,
      itemBuilder: (context, index) => const ProductCardSkeleton(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.w, color: ColorsManager.error),
            SizedBox(height: 16.h),
            Text(
              'Failed to load favorites',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage ?? 'Unknown error',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: ColorsManager.grey600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loadFavourites,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32.w),
              decoration: const BoxDecoration(
                gradient: ColorsManager.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 64.w,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Favorites Yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Text(
              'Start adding products to your favorites\nto see them here',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: ColorsManager.grey600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                RoutesManager.mainLayout,
              ),
              icon: const Icon(Icons.explore),
              label: const Text('Explore Items'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavouritesList() {
    return RefreshIndicator(
      onRefresh: _loadFavourites,
      child: ListView.builder(
        padding: EdgeInsets.all(20.w),
        itemCount: _favouriteProducts!.length,
        itemBuilder: (context, index) {
          final product = _favouriteProducts![index];
          return _buildFavouriteCard(product);
        },
      ),
    );
  }

  Widget _buildFavouriteCard(ProductModel product) {
    final firstImage = product.images.isNotEmpty ? product.images.first : null;

    return Card(
      elevation: 4,
      shadowColor: Theme.of(context).primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      margin: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).pushNamed(RoutesManager.productDetails, arguments: product.id);
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Container(
                width: 90.w,
                height: 90.w,
                decoration: BoxDecoration(
                  gradient: firstImage != null
                      ? null
                      : LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.1),
                            Theme.of(context).primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(12.r),
                  image: firstImage != null
                      ? DecorationImage(
                          image: NetworkImage(firstImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: firstImage == null
                    ? Icon(
                        Icons.image,
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        size: 36.w,
                      )
                    : null,
              ),
              SizedBox(width: 16.w),

              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      product.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ColorsManager.grey600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 4.h,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: ColorsManager.primaryLight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            product.category,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: ColorsManager.primaryLight,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10.sp,
                                    ),
                          ),
                        ),
                        _buildBadge(
                          product.status.name.toUpperCase(),
                          color: _getStatusColor(product.status.name),
                        ),
                        _buildBadge(
                          product.transactionType == TransactionType.sell
                              ? 'BUY${product.price != null ? ' - \$${product.price!.toStringAsFixed(0)}' : ''}'
                              : 'SWAP',
                          color: product.transactionType == TransactionType.sell
                              ? Colors.orange[800]!
                              : Colors.deepPurple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Remove button
              IconButton(
                onPressed: () => _removeFromFavourites(product),
                icon: const Icon(Icons.favorite),
                color: Colors.red,
                iconSize: 24.w,
                tooltip: 'Remove from favorites',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'traded':
        return Colors.blue;
      case 'unavailable':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBadge(String text, {required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10.sp,
            ),
      ),
    );
  }
}
