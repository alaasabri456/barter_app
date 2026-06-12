// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../features/authentication/models/user_model.dart';
import '../../features/authentication/widgets/auth_button.dart';
import '../../features/trade/models/trade_offer.dart';
import 'package:provider/provider.dart';
import 'viewmodels/review_viewmodel.dart';
import 'models/review_model.dart';

class LeaveReviewScreen extends StatefulWidget {
  final TradeOffer trade;
  final String targetUserId;
  final String targetUserName;

  const LeaveReviewScreen({
    super.key,
    required this.trade,
    required this.targetUserId,
    required this.targetUserName,
  });

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final user = UserModel.currentUser;
    if (user == null) return;

    if (_commentController.text.trim().isEmpty) {
      showInfoDialog(
        context: context,
        title: 'Error',
        message: 'Please write a comment',
        icon: Icons.error_outline,
        iconColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final review = ReviewModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        reviewerId: user.id,
        reviewerName: user.name,
        targetUserId: widget.targetUserId,
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
        tradeId: widget.trade.id,
      );

      await context.read<ReviewViewModel>().addReview(review);

      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Success',
          message: 'Review submitted successfully!',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        showInfoDialog(
          context: context,
          title: 'Error',
          message: 'Failed to submit review: $e',
          icon: Icons.error_outline,
          iconColor: Theme.of(context).colorScheme.error,
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
      appBar: CustomAppBar(title: 'Leave a Review'),
      body: LoadingOverlay(
        isLoading: _isLoading,
        loadingMessage: 'Submitting review...',
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.person,
                  size: 40.w,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 16.h),

              Text(
                'Rate your experience with',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 4.h),
              Text(
                widget.targetUserName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 32.h),

              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                    },
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40.w,
                    ),
                    padding: EdgeInsets.zero,
                  );
                }),
              ),

              SizedBox(height: 32.h),

              // Comment Input
              TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Write your review here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),

              SizedBox(height: 32.h),

              AuthButton(text: 'Submit Review', onPressed: _submitReview),
            ],
          ),
        ),
      ),
    );
  }
}
