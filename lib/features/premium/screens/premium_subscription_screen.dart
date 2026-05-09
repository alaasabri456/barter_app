// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../authentication/models/user_model.dart';
import '../../payment/models/payment_model.dart';
import '../../../firebase/firebase_service.dart';
import '../../../services/payment_service.dart';
import '../models/premium_subscription.dart';
import '../services/premium_service.dart';
import '../widgets/premium_badge_widget.dart';
import '../../authentication/widgets/auth_button.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_dialog.dart';

class PremiumSubscriptionScreen extends StatefulWidget {
  const PremiumSubscriptionScreen({super.key});

  @override
  State<PremiumSubscriptionScreen> createState() =>
      _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  PremiumSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    final userId = UserModel.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final sub = await PremiumService.getSubscription(userId);
      if (mounted) {
        setState(() {
          _subscription = sub;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isCurrentlyPremium => _subscription?.isActive ?? false;

  Future<void> _handleSubscribe() async {
    final user = UserModel.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);
    try {
      // Launch Paymob payment
      final response = await PaymentService.pay(
        amount: PremiumService.premiumPrice,
        context: context,
        user: user,
      );

      if (response == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payment was cancelled.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (!response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payment was declined. Please try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final transactionId = response.transactionID?.toString() ?? '';

      // Activate premium
      await PremiumService.activatePremium(
        userId: user.id,
        transactionId: transactionId,
        amountPaid: PremiumService.premiumPrice,
      );

      // Save payment record
      final payment = PaymentModel(
        id: '',
        buyerId: user.id,
        buyerName: user.name,
        sellerId: 'barter_premium',
        productId: 'premium_subscription',
        productTitle: 'Premium Subscription',
        amount: PremiumService.premiumPrice,
        currency: 'EGP',
        transactionId: transactionId,
        status: PaymentStatus.completed,
        createdAt: DateTime.now(),
      );
      await FirebaseService.savePayment(payment);

      // Reload
      await _loadSubscription();

      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Welcome to Premium! 🎉',
          message:
              'Your premium subscription is now active. Enjoy all the exclusive benefits!',
          icon: Icons.workspace_premium,
          iconColor: const Color(0xFFFFB800),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Premium'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Hero section
                  _buildHeroSection(theme),

                  // Status card (if premium)
                  if (_isCurrentlyPremium) _buildStatusCard(theme),

                  // Benefits section
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Benefits',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _buildBenefitTile(
                          icon: Icons.all_inclusive,
                          title: 'Unlimited Listings',
                          description:
                              'List as many products as you want — no 5-item cap.',
                          theme: theme,
                        ),
                        _buildBenefitTile(
                          icon: Icons.trending_up,
                          title: 'Boosted Visibility',
                          description:
                              'Your products appear at the top of the feed.',
                          theme: theme,
                        ),
                        _buildBenefitTile(
                          icon: Icons.workspace_premium,
                          title: 'Premium Badge',
                          description:
                              'Stand out with a golden badge on your profile & listings.',
                          theme: theme,
                        ),
                        _buildBenefitTile(
                          icon: Icons.discount,
                          title: 'Reduced Fees',
                          description:
                              'Only 2% service fee on purchases (instead of 5%).',
                          theme: theme,
                        ),
                        _buildBenefitTile(
                          icon: Icons.verified,
                          title: 'Verified Profile',
                          description:
                              'Build trust with a verified premium indicator.',
                          theme: theme,
                        ),
                        SizedBox(height: 24.h),

                        // Comparison table
                        _buildComparisonTable(theme),

                        SizedBox(height: 32.h),

                        // Subscribe button
                        if (!_isCurrentlyPremium) ...[
                          SizedBox(
                            width: double.infinity,
                            child: _buildSubscribeButton(theme),
                          ),
                          SizedBox(height: 12.h),
                          Center(
                            child: Text(
                              'Cancel anytime. No hidden fees.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: AuthButton(
                              text: 'Extend Subscription',
                              onPressed: _isProcessing ? null : _handleSubscribe,
                              isLoading: _isProcessing,
                              isOutlined: true,
                            ),
                          ),
                        ],

                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFB800), Color(0xFFFF8C00), Color(0xFFE65100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.workspace_premium,
            size: 64.w,
            color: Colors.white,
          ),
          SizedBox(height: 16.h),
          Text(
            'Barter Premium',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Unlock the full power of Barter',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Text(
              '${PremiumService.premiumPrice.toStringAsFixed(2)} EGP / month',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFFFB800).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const PremiumBadgeWidget.compact(),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Active ✨',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE65100),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_subscription!.daysRemaining} days remaining',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFFE65100).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitTile({
    required IconData icon,
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, size: 22.w, color: Colors.white),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Feature',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Free',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildComparisonRow('Listings', '5 items', 'Unlimited', theme),
          _buildComparisonRow('Feed boost', '—', '✓', theme),
          _buildComparisonRow('Profile badge', '—', '✓', theme),
          _buildComparisonRow('Service fee', '5%', '2%', theme),
          _buildComparisonRow('Verified', '—', '✓', theme, isLast: true),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String feature,
    String free,
    String premium,
    ThemeData theme, {
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
          Expanded(
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              premium,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE65100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB800), Color(0xFFFF8C00), Color(0xFFE65100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB800).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isProcessing ? null : _handleSubscribe,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: _isProcessing
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 22.w,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Subscribe Now',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
