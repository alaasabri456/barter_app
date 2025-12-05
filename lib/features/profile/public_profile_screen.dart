import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../features/trade/models/trade_offer.dart';
import '../../firebase/firebase_service.dart';
import '../reviews/reviews_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProfileStats();
  }

  Future<void> _loadProfileStats() async {
    try {
      // Load products count
      final products = await FirebaseService.getUserProducts(
        widget.userId,
        context,
      );

      // Load trades count
      final sentTrades = await FirebaseService.getSentTrades(widget.userId);
      final receivedTrades = await FirebaseService.getReceivedTrades(
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
      final reviews = await FirebaseService.getUserReviews(widget.userId);

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
                  Text(
                    widget.userName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
