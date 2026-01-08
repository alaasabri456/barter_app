// screens/trade/trade_management_screen.dart
// ignore_for_file: deprecated_member_use, unnecessary_underscores, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/loading_widget.dart';
import '../../firebase/firebase_service.dart';
import '../../features/trade/models/trade_offer.dart';
import '../../features/authentication/models/user_model.dart';
import '../../features/products/models/product_model.dart';
import '../authentication/widgets/auth_button.dart';
import '../../core/routes_manager/routes_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

    // Debug: Check received trades
    _debugCheckTrades();

    // Check for expired trades periodically
    FirebaseService.checkAndExpireTrades();
  }

  Future<void> _debugCheckTrades() async {
    final user = UserModel.currentUser;
    if (user != null) {
      await FirebaseService.debugCheckReceivedTrades(user.id);
    }
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
    }
  }

  Future<void> _acceptTrade(TradeOffer trade) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await FirebaseService.updateTradeStatus(
        tradeId: trade.id,
        newStatus: TradeStatus.accepted,
        userId: UserModel.currentUser!.id,
        userName: UserModel.currentUser!.name,
      );
      // Mark the main requested product as traded
      // Use the first requested product ID (the main product being traded for)
      if (trade.requestedProductIds.isNotEmpty) {
        final mainProductId = trade.requestedProductIds.first;
        await FirebaseService.updateProductAvailability(
          productId: mainProductId,
          isAvailable: false,
          newStatus: ProductStatus.traded,
        );
      }

      // Also mark offered products as traded
      if (trade.offeredProductIds.isNotEmpty) {
        for (final offeredProductId in trade.offeredProductIds) {
          await FirebaseService.updateProductAvailability(
            productId: offeredProductId,
            isAvailable: false,
            newStatus: ProductStatus.traded,
          );
        }
      }

      // Optional: Reject all other pending trades for the requested product
      if (trade.requestedProductIds.isNotEmpty) {
        final mainProductId = trade.requestedProductIds.first;
        await FirebaseService.rejectOtherTradeOffers(
          productId: mainProductId,
          acceptedTradeId: trade.id,
        );
      }

      // Reload trades
      await _loadTrades();

      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Trade Accepted',
          message: 'You have accepted the trade offer!',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Error',
          message: 'Failed to accept trade: $e',
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rejectTrade(TradeOffer trade) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Reject Trade',
      message: 'Are you sure you want to reject this trade offer?',
      confirmText: 'Reject',
      cancelText: 'Cancel',
      icon: Icons.cancel_outlined,
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await FirebaseService.updateTradeStatus(
        tradeId: trade.id,
        newStatus: TradeStatus.rejected,
        userId: UserModel.currentUser!.id,
        userName: UserModel.currentUser!.name,
      );

      // Reload trades
      await _loadTrades();

      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Trade Rejected',
          message: 'You have rejected the trade offer.',
          icon: Icons.cancel,
          iconColor: Colors.orange,
        );
      }
    } catch (e) {
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Error',
          message: 'Failed to reject trade: $e',
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelTrade(TradeOffer trade) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Cancel Trade',
      message: 'Are you sure you want to cancel this trade offer?',
      confirmText: 'Cancel Trade',
      cancelText: 'Keep',
      icon: Icons.delete_outline,
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await FirebaseService.updateTradeStatus(
        tradeId: trade.id,
        newStatus: TradeStatus.cancelled,
        userId: UserModel.currentUser!.id,
        userName: UserModel.currentUser!.name,
      );

      // Reload trades
      await _loadTrades();

      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Trade Cancelled',
          message: 'Your trade offer has been cancelled.',
          icon: Icons.cancel,
          iconColor: Colors.grey,
        );
      }
    } catch (e) {
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Error',
          message: 'Failed to cancel trade: $e',
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeTrade(TradeOffer trade) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Complete Trade',
      message: 'Has the exchange been successfully completed?',
      confirmText: 'Yes, Complete',
      cancelText: 'Not yet',
      icon: Icons.check_circle_outline,
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await FirebaseService.updateTradeStatus(
        tradeId: trade.id,
        newStatus: TradeStatus.completed,
        userId: UserModel.currentUser!.id,
        userName: UserModel.currentUser!.name,
      );

      // Reload trades
      await _loadTrades();

      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Trade Completed',
          message: 'Trade marked as complete! You can now leave a review.',
          icon: Icons.celebration,
          iconColor: Colors.purple,
        );
      }
    } catch (e) {
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Error',
          message: 'Failed to complete trade: $e',
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.3),
            ),
            SizedBox(height: 16.h),
            Text(
              isReceived ? 'No trade requests' : 'No sent trades',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8.h),
            Text(
              isReceived
                  ? 'Trade requests will appear here when other users offer trades'
                  : 'Your trade offers will appear here',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        trade.status,
                      ).withValues(alpha: 0.1),
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
                  Row(
                    children: [
                      // Chat Button with Notification Badge
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.chat_bubble_outline,
                              size: 20.w,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: () async {
                              await Navigator.pushNamed(
                                context,
                                RoutesManager.chat,
                                arguments: {
                                  'tradeId': trade.id,
                                  'otherUserId': isReceived
                                      ? trade.fromUserId
                                      : trade.toUserId,
                                  'otherUserName': isReceived
                                      ? trade.fromUserName
                                      : trade.toUserName,
                                },
                              );
                              _loadTrades(); // Reload to clear badge
                            },
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                          if (trade.hasUnreadMessages &&
                              trade.lastMessageSenderId !=
                                  UserModel.currentUser?.id)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 8.w,
                                  minHeight: 8.w,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _getTimeAgo(trade.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Trade parties info
              Row(
                children: [
                  Icon(
                    isReceived ? Icons.person_outline : Icons.person,
                    size: 16.w,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      isReceived
                          ? 'From: ${trade.fromUserName}'
                          : 'To: ${trade.toUserName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Trade items - Visual Product Cards
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Products being offered (what the receiver gets)
                  Text(
                    'You ${isReceived ? 'receive' : 'offer'}:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 8.h),
                  FutureBuilder<List<ProductModel>>(
                    future: _getProducts(trade.offeredProductIds),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: 80.h,
                          child: Center(
                            child: SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final products = snapshot.data ?? [];
                      if (products.isEmpty) {
                        return Text(
                          'No items',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      }
                      return SizedBox(
                        height: 80.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: products.length,
                          separatorBuilder: (_, __) => SizedBox(width: 8.w),
                          itemBuilder: (context, index) {
                            return _buildProductMiniCard(products[index]);
                          },
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 12.h),

                  // Swap icon
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Icon(
                        Icons.swap_vert,
                        size: 20.w,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Products being requested (what the sender wants)
                  Text(
                    'You ${isReceived ? 'give' : 'receive'}:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 8.h),
                  FutureBuilder<List<ProductModel>>(
                    future: _getProducts(trade.requestedProductIds),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: 80.h,
                          child: Center(
                            child: SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final products = snapshot.data ?? [];
                      if (products.isEmpty) {
                        return Text(
                          'No items',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      }
                      return SizedBox(
                        height: 80.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: products.length,
                          separatorBuilder: (_, __) => SizedBox(width: 8.w),
                          itemBuilder: (context, index) {
                            return _buildProductMiniCard(products[index]);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Counter offers indicator
              if (trade.counterOffers.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
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
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _getExpiryProgress(trade.expiresAt),
                      backgroundColor: Theme.of(context).dividerColor,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expires in ${_getTimeUntil(trade.expiresAt)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                        ),
                        Text(
                          '${_getDaysUntil(trade.expiresAt)} days left',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).primaryColor,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
              ],

              // Action buttons
              if (isReceived && trade.status == TradeStatus.pending) ...[
                Row(
                  children: [
                    Expanded(
                      child: AuthButton(
                        text: 'Accept',
                        onPressed: () => _acceptTrade(trade),
                        isOutlined: false,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: AuthButton(
                        text: 'Reject',
                        onPressed: () => _rejectTrade(trade),
                        isOutlined: true,
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ] else if (!isReceived &&
                  trade.status == TradeStatus.pending) ...[
                AuthButton(
                  text: 'Cancel Trade',
                  onPressed: () => _cancelTrade(trade),
                  isOutlined: true,
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              ] else if (trade.status == TradeStatus.accepted) ...[
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16.w,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Trade accepted! Coordinate via chat.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    AuthButton(
                      text: 'Complete Trade',
                      onPressed: () => _completeTrade(trade),
                      backgroundColor: Colors.purple,
                    ),
                  ],
                ),
              ] else if (trade.status == TradeStatus.completed) ...[
                AuthButton(
                  text: 'Leave a Review',
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      RoutesManager.leaveReview,
                      arguments: {
                        'trade': trade,
                        'targetUserId':
                            isReceived ? trade.fromUserId : trade.toUserId,
                        'targetUserName':
                            isReceived ? trade.fromUserName : trade.toUserName,
                      },
                    );

                    if (result == true) {
                      // Maybe disable button or show "Reviewed" text.
                      // For now, simpler is better.
                    }
                  },
                  isOutlined: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<List<ProductModel>> _getProducts(List<String> productIds) async {
    try {
      if (productIds.isEmpty) return [];

      final products = await FirebaseService.getProductsByIds(
        productIds,
        context,
      );
      return products;
    } catch (e) {
      print('=== DEBUG: Error getting products: $e ===');
      return [];
    }
  }

  Widget _buildProductMiniCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          RoutesManager.productDetails,
          arguments: product.id,
        );
      },
      child: Container(
        width: 140.w,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 60.w,
              height: 78.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(9.r),
                  bottomLeft: Radius.circular(9.r),
                ),
                color: Colors.grey[200],
                image: product.images.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(product.images.first),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.images.isEmpty
                  ? Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 24.w,
                        color: Colors.grey[400],
                      ),
                    )
                  : null,
            ),
            // Product Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11.sp,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 10.w,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Tap to view',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    switch (status) {
      case TradeStatus.pending:
        return 'PENDING';
      case TradeStatus.accepted:
        return 'ACCEPTED';
      case TradeStatus.rejected:
        return 'REJECTED';
      case TradeStatus.expired:
        return 'EXPIRED';
      case TradeStatus.completed:
        return 'COMPLETED';
      case TradeStatus.cancelled:
        return 'CANCELLED';
    }
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

  int _getDaysUntil(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    return difference.inDays;
  }

  double _getExpiryProgress(DateTime expiresAt) {
    final now = DateTime.now();
    final totalDuration = expiresAt.difference(
      expiresAt.subtract(const Duration(days: 7)),
    );
    final remainingDuration = expiresAt.difference(now);

    return 1 - (remainingDuration.inSeconds / totalDuration.inSeconds);
  }
}
