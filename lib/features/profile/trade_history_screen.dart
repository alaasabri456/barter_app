import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/loading_widget.dart';
import '../../features/authentication/models/user_model.dart';
import '../../features/trade/models/trade_offer.dart';
import '../../firebase/firebase_service.dart';

class TradeHistoryScreen extends StatefulWidget {
  const TradeHistoryScreen({super.key});

  @override
  State<TradeHistoryScreen> createState() => _TradeHistoryScreenState();
}

class _TradeHistoryScreenState extends State<TradeHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<TradeOffer> _sentTrades = [];
  List<TradeOffer> _receivedTrades = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTrades();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrades() async {
    final user = UserModel.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Please log in to view trade history';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sent = await FirebaseService.getSentTrades(user.id);
      final received = await FirebaseService.getReceivedTrades(user.id);

      setState(() {
        _sentTrades = sent;
        _receivedTrades = received;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load trade history: $e';
        _isLoading = false;
      });
    }
  }

  List<TradeOffer> get _completedTrades {
    final all = [..._sentTrades, ..._receivedTrades];
    return all
        .where(
          (trade) =>
              trade.status == TradeStatus.accepted ||
              trade.status == TradeStatus.completed,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Trade History'),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Sent'),
                Tab(text: 'Received'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: LoadingOverlay(
              isLoading: _isLoading,
              loadingMessage: 'Loading trade history...',
              child: _errorMessage != null
                  ? _buildErrorState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTradesList(_completedTrades),
                        _buildTradesList(
                          _sentTrades
                              .where(
                                (t) =>
                                    t.status == TradeStatus.accepted ||
                                    t.status == TradeStatus.completed,
                              )
                              .toList(),
                        ),
                        _buildTradesList(
                          _receivedTrades
                              .where(
                                (t) =>
                                    t.status == TradeStatus.accepted ||
                                    t.status == TradeStatus.completed,
                              )
                              .toList(),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.w,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(height: 16.h),
          Text(
            'Error Loading Trade History',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              _errorMessage ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(onPressed: _loadTrades, child: Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildTradesList(List<TradeOffer> trades) {
    if (trades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64.w,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
            ),
            SizedBox(height: 16.h),
            Text(
              'No completed trades yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.titleMedium?.color?.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your completed trades will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
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
          final user = UserModel.currentUser;
          final isSent = trade.fromUserId == user?.id;

          return _buildTradeCard(trade, isSent);
        },
      ),
    );
  }

  Widget _buildTradeCard(TradeOffer trade, bool isSent) {
    final otherUserName = isSent ? trade.toUserName : trade.fromUserName;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () {
          // Navigate to trade details
          //  _showTradeDetails(trade, isSent);
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Icon(
                    isSent ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isSent ? Colors.orange : Colors.green,
                    size: 20.w,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      isSent
                          ? 'Traded with $otherUserName'
                          : 'Received from $otherUserName',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(trade.status),
                ],
              ),

              SizedBox(height: 12.h),

              // Trade type and date
              Row(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 16.w,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    trade.type.name.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Icon(
                    Icons.calendar_today,
                    size: 16.w,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    dateFormat.format(trade.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Products info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSent ? 'You offered' : 'You received',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${isSent ? trade.offeredProductIds.length : trade.requestedProductIds.length} item(s)',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.swap_horiz, color: Theme.of(context).primaryColor),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isSent ? 'You received' : 'They offered',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${isSent ? trade.requestedProductIds.length : trade.offeredProductIds.length} item(s)',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(TradeStatus status) {
    Color color;
    String label;

    switch (status) {
      case TradeStatus.accepted:
        color = Colors.green;
        label = 'Accepted';
        break;
      case TradeStatus.completed:
        color = Colors.blue;
        label = 'Completed';
        break;
      default:
        color = Colors.grey;
        label = status.name;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
