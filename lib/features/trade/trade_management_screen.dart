// screens/trade/trade_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/loading_widget.dart';
import '../../firebase/firebase_service.dart';
import '../../models/trade_offer.dart';
import '../../models/user_model.dart';

class TradeManagementScreen extends StatefulWidget {
  const TradeManagementScreen({super.key});

  @override
  State<TradeManagementScreen> createState() => _TradeManagementScreenState();
}

class _TradeManagementScreenState extends State<TradeManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TradeOffer> _receivedTrades = [];
  List<TradeOffer> _sentTrades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrades();

    // Check for expired trades periodically
    FirebaseService.checkAndExpireTrades();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrades() async {
    try {
      final user = UserModel.currentUser!;
      final [received, sent] = await Future.wait([
        FirebaseService.getReceivedTrades(user.id),
        FirebaseService.getSentTrades(user.id),
      ]);

      setState(() {
        _receivedTrades = received;
        _sentTrades = sent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Trade Management',
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Received'),
                Tab(text: 'Sent'),
              ],
            ),
          ),

          Expanded(
            child: LoadingOverlay(
              isLoading: _isLoading,
              loadingMessage: 'Loading trades...',
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTradesList(_receivedTrades, isReceived: true),
                  _buildTradesList(_sentTrades, isReceived: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradesList(List<TradeOffer> trades, {required bool isReceived}) {
    if (trades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz,
              size: 64.w,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
            ),
            SizedBox(height: 16.h),
            Text(
              isReceived ? 'No trade requests' : 'No sent trades',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8.h),
            Text(
              isReceived
                  ? 'Trade requests will appear here'
                  : 'Your trade offers will appear here',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrades,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: trades.length,
        itemBuilder: (context, index) {
          final trade = trades[index];
          return _buildTradeCard(trade, isReceived: isReceived);
        },
      ),
    );
  }

  Widget _buildTradeCard(TradeOffer trade, {required bool isReceived}) {
    final isExpired = trade.status == TradeStatus.expired;
    final isPending = trade.status == TradeStatus.pending;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: InkWell(
          onTap: () {
            // Navigate to trade details
            _showTradeDetails(trade, isReceived: isReceived);
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor(trade.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        _getStatusText(trade.status),
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(trade.status),
                        ),
                      ),
                    ),
                    Text(
                      _getTimeAgo(trade.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Trade parties
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You ${isReceived ? 'receive' : 'offer'}:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${trade.offeredProductIds.length} item${trade.offeredProductIds.length != 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.swap_horiz, size: 20.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'You ${isReceived ? 'offer' : 'receive'}:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${trade.requestedProductIds.length} item${trade.requestedProductIds.length != 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Counter offers indicator
                if (trade.counterOffers.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.countertops, size: 12.w, color: Colors.orange),
                        SizedBox(width: 4.w),
                        Text(
                          '${trade.counterOffers.length} counter offer${trade.counterOffers.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],

                // Expiry timer for pending trades
                if (isPending && !isExpired) ...[
                  LinearProgressIndicator(
                    value: _getExpiryProgress(trade.expiresAt),
                    backgroundColor: Theme.of(context).dividerColor,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Expires in ${_getTimeUntil(trade.expiresAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(TradeStatus status) {
    switch (status) {
      case TradeStatus.pending:
        return Colors.orange;
      case TradeStatus.accepted:
        return Colors.green;
      case TradeStatus.rejected:
        return Colors.red;
      case TradeStatus.expired:
        return Colors.grey;
      case TradeStatus.completed:
        return Colors.blue;
      case TradeStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(TradeStatus status) {
    return status.name.toUpperCase();
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getTimeUntil(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours';
    } else {
      return 'Less than an hour';
    }
  }

  double _getExpiryProgress(DateTime expiresAt) {
    final now = DateTime.now();
    final totalDuration = expiresAt.difference(expiresAt.subtract(const Duration(days: 7)));
    final remainingDuration = expiresAt.difference(now);

    return 1 - (remainingDuration.inSeconds / totalDuration.inSeconds);
  }

  void _showTradeDetails(TradeOffer trade, {required bool isReceived}) {
    // Implement trade details screen navigation
    // This would show full trade details, counter offers, and action buttons
  }
}