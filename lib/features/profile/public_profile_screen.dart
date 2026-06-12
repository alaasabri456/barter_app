// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../features/trade/models/trade_offer.dart';
import 'package:provider/provider.dart';
import '../products/viewmodels/product_viewmodel.dart';
import '../trade/viewmodels/trade_viewmodel.dart';
import '../reviews/viewmodels/review_viewmodel.dart';
import '../reviews/reviews_screen.dart';
import '../premium/widgets/premium_badge_widget.dart';
import '../premium/services/premium_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  int _createdProductsCount = 0;
  int _completedTradesCount = 0;
  int _reviewsCount = 0;
  bool _isUserPremium = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileStats();
      _loadPremiumStatus();
    });
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final isPremium = await PremiumService.isUserPremium(widget.userId);
      if (mounted) {
        setState(() => _isUserPremium = isPremium);
      }
    } catch (_) {}
  }

  Future<void> _loadProfileStats() async {
    try {
      // Load products count
      final products = await context.read<ProductViewModel>().getUserProducts(
        widget.userId,
      );

      // Load trades count
      final sentTrades = await context.read<TradeViewModel>().getSentTrades(widget.userId);
      final receivedTrades = await context.read<TradeViewModel>().getReceivedTrades(
        widget.userId,
      );

      final completedTrades = [...sentTrades, ...receivedTrades]
          .where(
            (t) =>
                t.status == TradeStatus.accepted ||
                t.status == TradeStatus.completed,
          )
          .length;

      // Load reviews count
      final reviews = await context.read<ReviewViewModel>().getUserReviews(widget.userId);

      if (mounted) {
        setState(() {
          _createdProductsCount = products.length;
          _completedTradesCount = completedTrades;
          _reviewsCount = reviews.length;
        });
      }
    } catch (e) {
      print('Error loading public profile stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.userName),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Profile avatar
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Icon(Icons.person, size: 50.w, color: Colors.white),
                  ),

                  SizedBox(height: 16.h),

                  // User name
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.userName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isUserPremium) ...[
                        SizedBox(width: 8.w),
                        const PremiumBadgeWidget.compact(),
                      ],
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Products', '$_createdProductsCount'),
                      Container(
                        height: 40.h,
                        width: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildStatItem('Trades', '$_completedTradesCount'),
                      Container(
                        height: 40.h,
                        width: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildStatItem(
                        'Reviews',
                        '$_reviewsCount',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReviewsScreen(userId: widget.userId),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Here we could add a list of the user's active products in the future
            // For now, it's just the stats
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
