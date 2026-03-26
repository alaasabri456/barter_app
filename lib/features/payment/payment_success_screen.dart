// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/routes_manager/routes_manager.dart';
import '../../features/products/models/product_model.dart';
import '../authentication/widgets/auth_button.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final ProductModel product;
  final double totalPaid;
  final String transactionId;

  const PaymentSuccessScreen({
    super.key,
    required this.product,
    required this.totalPaid,
    required this.transactionId,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success Animation
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.35),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 64.w,
                  ),
                ),
              ),

              SizedBox(height: 28.h),

              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your purchase is confirmed.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // Order Details Card
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'Item',
                        widget.product.title,
                        theme,
                        isBold: true,
                      ),
                      SizedBox(height: 12.h),
                      _buildDetailRow(
                        'Amount Paid',
                        '${widget.totalPaid.toStringAsFixed(2)} EGP',
                        theme,
                        valueColor: Colors.green,
                      ),
                      SizedBox(height: 12.h),
                      _buildDetailRow(
                        'Reference',
                        widget.transactionId,
                        theme,
                        isSmall: true,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Back to Home button
              AuthButton(
                text: 'Back to Home',
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    RoutesManager.mainLayout,
                    (route) => false,
                  );
                },
                icon: Icon(Icons.home_outlined, size: 20.w),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ThemeData theme, {
    bool isBold = false,
    bool isSmall = false,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 12.sp : 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
