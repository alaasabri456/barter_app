// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/authentication/models/user_model.dart';
import '../../features/payment/models/payment_model.dart';
import '../../features/products/models/product_model.dart';
import '../../firebase/firebase_service.dart';
import '../../services/payment_service.dart';
import '../authentication/widgets/auth_button.dart';
import 'payment_success_screen.dart';
import '../premium/services/premium_service.dart';

class CheckoutScreen extends StatefulWidget {
  final ProductModel product;

  const CheckoutScreen({super.key, required this.product});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;

  double get _price => widget.product.price ?? 0.0;
  double get _serviceFeePercent =>
      PremiumService.getServiceFeePercent(UserModel.currentUser?.isPremium ?? false);
  double get _serviceFee => _price * _serviceFeePercent;
  double get _total => _price + _serviceFee;

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    try {
      final user = UserModel.currentUser;
      if (user == null) throw Exception('Please log in to continue.');

      // Launch Paymob WebView checkout
      final response = await PaymentService.pay(
        amount: _total,
        context: context,
        user: user,
      );

      // User dismissed the WebView without completing payment
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

      // Payment was declined or failed
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

      // Save payment record to Firestore
      final transactionId = response.transactionID?.toString().trim() ?? '';
      final payment = PaymentModel(
        id: '',
        buyerId: user.id,
        buyerName: user.name,
        sellerId: widget.product.ownerId,
        productId: widget.product.id,
        productTitle: widget.product.title,
        amount: _total,
        currency: 'EGP',
        transactionId: transactionId,
        status: PaymentStatus.completed,
        createdAt: DateTime.now(),
      );

      await FirebaseService.savePayment(payment);

      // Mark product as traded/sold
      await FirebaseService.updateProductAvailability(
        productId: widget.product.id,
        isAvailable: false,
        newStatus: ProductStatus.traded,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              product: widget.product,
              totalPaid: _total,
              transactionId: transactionId,
            ),
          ),
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
    final product = widget.product;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Card
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Product image
                          ClipRRect(
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(20.r),
                            ),
                            child: product.images.isNotEmpty
                                ? Image.network(
                                    product.images.first,
                                    width: 110.w,
                                    height: 110.h,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 110.w,
                                    height: 110.h,
                                    color: theme.primaryColor.withOpacity(0.1),
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 40.w,
                                      color:
                                          theme.primaryColor.withOpacity(0.4),
                                    ),
                                  ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(14.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.title,
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Sold by ${product.ownerName}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withOpacity(0.7),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      product.condition,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 28.h),

                    // Order Summary
                    Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [
                          _buildPriceRow('Item Price', _price, theme),
                          SizedBox(height: 12.h),
                          _buildPriceRow(
                              'Service Fee (${(_serviceFeePercent * 100).toInt()}%)',
                              _serviceFee,
                              theme,
                              isSmall: true),
                          if (UserModel.currentUser?.isPremium ?? false) ...[
                            SizedBox(height: 4.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.workspace_premium,
                                    size: 14.w, color: Colors.orange[800]),
                                SizedBox(width: 4.w),
                                Text(
                                  'Premium discount applied!',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          Divider(height: 24.h, color: theme.dividerColor),
                          _buildPriceRow('Total', _total, theme, isBold: true),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Secure payment badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14.w,
                          color: Colors.green,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Secured by Paymob · Your card is not stored',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Pay Now button
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: AuthButton(
                      text: 'Pay ${_total.toStringAsFixed(2)} EGP',
                      onPressed: _isProcessing ? null : _handlePayment,
                      isLoading: _isProcessing,
                      icon: Icon(Icons.payment_rounded, size: 20.w),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'You will be charged ${_total.toStringAsFixed(2)} EGP',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double value,
    ThemeData theme, {
    bool isBold = false,
    bool isSmall = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmall ? 13.sp : 14.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isSmall
                ? theme.textTheme.bodySmall?.color?.withOpacity(0.7)
                : null,
          ),
        ),
        Text(
          '${value.toStringAsFixed(2)} EGP',
          style: TextStyle(
            fontSize: isSmall ? 13.sp : 15.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? theme.primaryColor : null,
          ),
        ),
      ],
    );
  }
}
