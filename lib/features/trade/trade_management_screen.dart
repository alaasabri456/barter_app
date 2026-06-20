// screens/trade/trade_management_screen.dart
// ignore_for_file: deprecated_member_use, unnecessary_underscores, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import '../../features/trade/viewmodels/trade_viewmodel.dart';
import '../../features/products/viewmodels/product_viewmodel.dart';
import '../../features/trade/models/trade_offer.dart';
import '../../features/authentication/models/user_model.dart';
import '../../features/products/models/product_model.dart';
import '../authentication/widgets/auth_button.dart';
import '../../core/routes_manager/routes_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../premium/widgets/premium_badge_widget.dart';
import '../../services/delivery_service.dart';

class TradeManagementScreen extends StatefulWidget {
  const TradeManagementScreen({super.key});

  @override
  State<TradeManagementScreen> createState() => _TradeManagementScreenState();
}

class _TradeManagementScreenState extends State<TradeManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Debug: Check received trades
    _debugCheckTrades();

    // Check for expired trades periodically
    context.read<TradeViewModel>().checkAndExpireTrades();
  }

  Future<void> _debugCheckTrades() async {
    final user = UserModel.currentUser;
    if (user != null) {
      await context.read<TradeViewModel>().debugCheckReceivedTrades(user.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _acceptTrade(TradeOffer trade) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await context.read<TradeViewModel>().updateTradeStatus(
        tradeId: trade.id,
        newStatus: TradeStatus.accepted,
        userId: UserModel.currentUser!.id,
        userName: UserModel.currentUser!.name,
      );

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

      await context.read<TradeViewModel>().updateTradeStatus(
        tradeId: trade.id,
        newStatus: TradeStatus.rejected,
        userId: UserModel.currentUser!.id,
        userName: UserModel.currentUser!.name,
      );

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

      await context.read<TradeViewModel>().updateTradeStatus(
        tradeId: trade.id,
        newStatus: TradeStatus.cancelled,
        userId: UserModel.currentUser!.id,
        userName: UserModel.currentUser!.name,
      );

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

  Future<Map<String, String>?> _showDeliveryDetailsForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24.w,
            right: 24.w,
            top: 24.h,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Delivery Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Please provide your details for the delivery agent.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Full Address (Street, City, Governorate)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    maxLines: 2,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 32.h),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context, {
                          'fullName': nameController.text.trim(),
                          'phoneNumber': phoneController.text.trim(),
                          'address': addressController.text.trim(),
                        });
                      }
                    },
                    child: const Text('Confirm & Complete Trade'),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _completeTrade(TradeOffer trade) async {
    final deliveryDetails = await _showDeliveryDetailsForm(context);

    if (deliveryDetails == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await context.read<TradeViewModel>().updateTradeStatus(
        tradeId: trade.id,
        newStatus: TradeStatus.completed,
        userId: UserModel.currentUser!.id,
        userName: UserModel.currentUser!.name,
      );

      // Create a new delivery order for this completed trade
      try {
        await DeliveryService.createDelivery(
          userId: UserModel.currentUser!.id,
          itemName: 'Trade Items (${trade.id.substring(0, 5)})',
          fullName: deliveryDetails['fullName']!,
          phoneNumber: deliveryDetails['phoneNumber']!,
          address: deliveryDetails['address']!,
          tradeId: trade.id,
        );

        // Add user to trade's deliveryProvidedBy list
        await context.read<TradeViewModel>().addDeliveryProvidedByUser(
          tradeId: trade.id,
          userId: UserModel.currentUser!.id,
        );
      } catch (e) {
        print('Error creating delivery: $e');
      }

      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Trade Completed',
          message: 'Trade marked as complete! Your delivery order has been created. You can now leave a review.',
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

  Future<void> _provideDeliveryDetailsOnly(TradeOffer trade) async {
    final deliveryDetails = await _showDeliveryDetailsForm(context);

    if (deliveryDetails == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Create a new delivery order for this user
      await DeliveryService.createDelivery(
        userId: UserModel.currentUser!.id,
        itemName: 'Trade Items (${trade.id.substring(0, 5)})',
        fullName: deliveryDetails['fullName']!,
        phoneNumber: deliveryDetails['phoneNumber']!,
        address: deliveryDetails['address']!,
        tradeId: trade.id,
      );

      // Add user to trade's deliveryProvidedBy list
      await context.read<TradeViewModel>().addDeliveryProvidedByUser(
        tradeId: trade.id,
        userId: UserModel.currentUser!.id,
      );

      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Delivery Requested',
          message: 'Your delivery has been successfully scheduled!',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Error',
          message: 'Failed to schedule delivery: $e',
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
                  StreamBuilder<List<TradeOffer>>(
                    stream: context.read<TradeViewModel>().streamReceivedTrades(
                      UserModel.currentUser!.id,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final trades = snapshot.data ?? [];
                      return _buildTradesList(trades, isReceived: true);
                    },
                  ),
                  StreamBuilder<List<TradeOffer>>(
                    stream: context.read<TradeViewModel>().streamSentTrades(
                      UserModel.currentUser!.id,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final trades = snapshot.data ?? [];
                      return _buildTradesList(trades, isReceived: false);
                    },
                  ),
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

    // Filter out counter offers from the received list to show them grouped
    final filteredTrades = isReceived
        ? trades.where((t) => !t.isCounterOffer).toList()
        : trades;

    if (filteredTrades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48.w,
              color: Theme.of(context).disabledColor,
            ),
            SizedBox(height: 16.h),
            Text(
              'No items found here.',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: filteredTrades.length,
      itemBuilder: (context, index) {
        final trade = filteredTrades[index];
        return _buildTradeCard(trade, isReceived: isReceived);
      },
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
                      _getStatusText(trade.status, isReceived: isReceived),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(trade.status),
                      ),
                    ),
                  ),
                  if (trade.isFromPremium) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.amber[700]!, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PremiumBadgeWidget.compact(),
                          SizedBox(width: 4.w),
                          Text(
                            'PREMIUM OFFER',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.amber[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (trade.isCounterOffer) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Text(
                        'COUNTER OFFER',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                  if (!trade.isCounterOffer && isReceived && isPending) ...[
                    SizedBox(width: 8.w),
                    FutureBuilder<int>(
                      future: context.read<TradeViewModel>().getPendingTradeCountForProduct(
                        trade.requestedProductIds.first,
                      ),
                      builder: (context, snapshot) {
                        final count = (snapshot.data ?? 1) - 1;
                        if (count <= 0) return const SizedBox.shrink();
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department,
                                  size: 12.w, color: Colors.red),
                              SizedBox(width: 4.w),
                              Text(
                                '$count COMPETING OFFER${count > 1 ? 'S' : ''}',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
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
                          height: 100.h,
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
                        height: 100.h,
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
                          height: 100.h,
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
                        height: 100.h,
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
                if (!isReceived) ...[
                  // If I'm the sender, I must confirm or reject
                  Row(
                    children: [
                      Expanded(
                        child: AuthButton(
                          text: 'Confirm Complete',
                          onPressed: () => _completeTrade(trade),
                          backgroundColor: Colors.purple,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: AuthButton(
                          text: 'Cancel trade',
                          onPressed: () => _rejectTrade(trade),
                          isOutlined: true,
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // If I'm the recipient (owner), I've already accepted, now waiting for sender
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_empty,
                            size: 16.w, color: Colors.orange),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Accepted. Waiting for requester to confirm completion.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else if (trade.status == TradeStatus.completed) ...[
                Builder(
                  builder: (context) {
                    final currentUserId = UserModel.currentUser?.id ?? '';
                    // FIX: Instead of relying on trade.deliveryProvidedBy (which
                    // requires a successful Firestore write that may be blocked by
                    // rules), we query the deliveries collection directly.
                    // This way "Track Delivery" appears as soon as a delivery doc
                    // exists for this trade, regardless of the trade document state.
                    return FutureBuilder<String?>(
                      future: DeliveryService.getDeliveryIdByTradeAndUser(
                        trade.id,
                        currentUserId,
                      ),
                      builder: (context, snapshot) {
                        final deliveryId = snapshot.data;
                        final hasDelivery = deliveryId != null;
                        return Row(
                          children: [
                            if (!hasDelivery)
                              Expanded(
                                child: AuthButton(
                                  text: 'Provide Delivery Details',
                                  onPressed: () => _provideDeliveryDetailsOnly(trade),
                                  backgroundColor: Colors.green,
                                ),
                              )
                            else
                              Expanded(
                                child: AuthButton(
                                  text: 'Track Delivery',
                                  onPressed: () async {
                                    if (deliveryId == null) return;
                                    Navigator.pushNamed(
                                      context,
                                      RoutesManager.deliveryStatus,
                                      arguments: deliveryId,
                                    );
                                  },
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: AuthButton(
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
                            ),
                          ],
                        );
                      },  // end FutureBuilder builder
                    );    // end FutureBuilder
                  },      // end outer Builder builder
                ),         // end outer Builder
              ],
              if (!trade.isCounterOffer && isReceived && isPending)
                _buildCounterOffersSection(trade),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterOffersSection(TradeOffer parentTrade) {
    return FutureBuilder<List<TradeOffer>>(
      future: context.read<TradeViewModel>().getCounterOffersForTrade(parentTrade.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final counterOffers = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                children: [
                  Icon(Icons.swap_calls, size: 16.w, color: Colors.orange),
                  SizedBox(width: 8.w),
                  Text(
                    'Competing Counter Offers (${counterOffers.length})',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),
            ...counterOffers.map((counter) => Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        counter.fromUserName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getTimeAgo(counter.createdAt),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 14.w, color: Colors.grey),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          'Offered: ${counter.offeredProductIds.length} items',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: AuthButton(
                          text: 'View & Accept',
                          height: 30,
                          onPressed: () {
                            // For now, maybe just show details or similar
                            // But simpler is to open a dialog or similar
                            // For MVP, let's just make it show the card details
                            _showCounterOfferDetails(counter);
                          },
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        );
      },
    );
  }

  void _showCounterOfferDetails(TradeOffer counterOffer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(12.w),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: _buildTradeCard(counterOffer, isReceived: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<ProductModel>> _getProducts(List<String> productIds) async {
    try {
      if (productIds.isEmpty) return [];

      final products = await context.read<ProductViewModel>().getProductsByIds(
        productIds,
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
        width: 150.w,
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
              height: 98.h,
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
        return Colors.purple;
      case TradeStatus.rejected:
        return Colors.red;
      case TradeStatus.expired:
        return Colors.grey;
      case TradeStatus.completed:
        return Colors.green;
      case TradeStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(TradeStatus status, {bool isReceived = true}) {
    switch (status) {
      case TradeStatus.pending:
        return 'PENDING';
      case TradeStatus.accepted:
        return isReceived
            ? 'WAITING FOR CONFIRMATION'
            : 'NEED YOUR CONFIRMATION';
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
