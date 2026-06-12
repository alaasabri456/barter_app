import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:provider/provider.dart';

import '../../authentication/viewmodels/auth_viewmodel.dart';
import '../viewmodels/wallet_viewmodel.dart';
import '../../authentication/models/user_model.dart';
import '../models/wallet_transaction_model.dart';
import '../models/withdrawal_request_model.dart';
import 'request_withdrawal_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = UserModel.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Wallet')),
        body: const Center(child: Text('Please log in to view your wallet.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Wallet',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Transactions'),
            Tab(text: 'Withdrawals'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Balance Card
          StreamBuilder<UserModel?>(
            stream: context.read<AuthViewModel>().currentUserStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error loading balance: ${snapshot.error}'));
              }
              
              final currentBalance = snapshot.data?.walletBalance ?? user.walletBalance;

              return Container(
                margin: EdgeInsets.all(16.w),
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${currentBalance.toStringAsFixed(2)} EGP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: currentBalance > 0
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RequestWithdrawalScreen(
                                        availableBalance: currentBalance,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: theme.primaryColor,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Withdraw',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Tabs Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionsTab(user.id),
                _buildWithdrawalsTab(user.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(String userId) {
    return StreamBuilder<List<WalletTransactionModel>>(
      stream: context.read<WalletViewModel>().getWalletTransactions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return const Center(child: Text('No transactions yet.'));
        }

        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isCredit = tx.type == TransactionType.credit;
            
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                child: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              title: Text(tx.description, style: TextStyle(fontSize: 14.sp)),
              subtitle: Text(
                _formatDate(tx.createdAt),
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
              trailing: Text(
                '${isCredit ? '+' : '-'}${tx.amount.toStringAsFixed(2)} EGP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCredit ? Colors.green : Colors.red,
                  fontSize: 14.sp,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWithdrawalsTab(String userId) {
    return StreamBuilder<List<WithdrawalRequestModel>>(
      stream: context.read<WalletViewModel>().getSellerWithdrawalRequests(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const Center(child: Text('No withdrawal requests yet.'));
        }

        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: requests.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final request = requests[index];
            
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${request.amount.toStringAsFixed(2)} EGP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp)),
              subtitle: Text(
                '${_formatDate(request.createdAt)}\n${request.bankDetails['bankName'] ?? 'Bank'} ending in ${(request.bankDetails['accountNumber'] as String?)?.runes.toList().reversed.take(4).toList().reversed.map((c) => String.fromCharCode(c)).join() ?? '****'}',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
              isThreeLine: true,
              trailing: _buildStatusBadge(request.status),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(WithdrawalStatus status) {
    Color color;
    String text;

    switch (status) {
      case WithdrawalStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case WithdrawalStatus.approved:
        color = Colors.blue;
        text = 'Approved';
        break;
      case WithdrawalStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case WithdrawalStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
