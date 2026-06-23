// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/authentication/models/user_model.dart';
import '../../features/payment/models/payment_model.dart';
import '../../features/products/models/product_model.dart';
import 'package:provider/provider.dart';
import '../../features/payment/viewmodels/payment_viewmodel.dart';
import '../../features/products/viewmodels/product_viewmodel.dart';
import '../../services/payment_service.dart';
import '../authentication/widgets/auth_button.dart';
import 'payment_success_screen.dart';
import '../premium/services/premium_service.dart';
import '../../core/error/error_handler.dart';

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
    final user = UserModel.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please log in to continue.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 1: Write a pending Payment doc to Firestore BEFORE opening Paymob.
    // This guarantees a transaction record exists even if the app crashes later.
    // ─────────────────────────────────────────────────────────────────────────
    String pendingDocId;
    try {
      pendingDocId = await context.read<PaymentViewModel>().createPendingPayment(
        PaymentModel(
          id: '',
          buyerId: user.id,
          buyerName: user.name,
          sellerId: widget.product.ownerId,
          productId: widget.product.id,
          productTitle: widget.product.title,
          amount: _total,
          currency: 'EGP',
          transactionId: '',      // filled in Phase 3
          status: PaymentStatus.pending,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start payment: ${ErrorHandler.getErrorMessage(e)}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 2: Open Paymob payment view (card + mobile wallet selector).
    // The new pay_with_paymob package uses callbacks instead of a Future.
    // ─────────────────────────────────────────────────────────────────────────
    
    // Capture ViewModels before the async gap
    final paymentVM = context.read<PaymentViewModel>();
    final productVM = context.read<ProductViewModel>();
    
    PaymentService.pay(
      amount: _total,
      context: context,
      user: user,
      onSuccess: () async {
        // ─────────────────────────────────────────────────────────────────────
        // PHASE 3: Payment confirmed — update the pending doc to completed.
        // The Cloud Function listens for this pending → completed transition
        // and credits the seller's wallet atomically.
        // ─────────────────────────────────────────────────────────────────────
        final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
        try {
          await paymentVM.updatePaymentToCompleted(
            docId: pendingDocId,
            transactionId: transactionId,
          );

          // Mark product as sold.
          await productVM.updateProductAvailability(
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
                content: Text('Payment succeeded but order save failed: ${ErrorHandler.getErrorMessage(e)}'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isProcessing = false);
        }
      },
      onError: () {
        // Mark the pending doc as cancelled/failed.
        paymentVM.updatePaymentStatus(
          docId: pendingDocId,
          status: PaymentStatus.cancelled,
        );
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payment failed or was cancelled. Please try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
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
                        Flexible(
                          child: Text(
                            'Secured by Paymob · Card or Mobile Wallet',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
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
