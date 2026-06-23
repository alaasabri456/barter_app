import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';
import '../../../core/routes_manager/routes_manager.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../services/email_service.dart';
import '../../../services/push_notification_service.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../../../core/error/error_handler.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String generatedOtp;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.generatedOtp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late String _currentOtp;

  @override
  void initState() {
    super.initState();
    _currentOtp = widget.generatedOtp;
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_otpController.text.trim() == _currentOtp) {
      setState(() {
        _isLoading = true;
      });
      // OTP matched, proceed
      await PushNotificationService.updateToken();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(RoutesManager.mainLayout, (route) => false);
      }
    } else {
      showInfoDialog(
        context: context,
        title: 'Verification Failed',
        message: 'The OTP code is incorrect. Please try again.',
        icon: Icons.error_outline,
        iconColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  void _resendOtp() async {
    setState(() {
      _isLoading = true;
    });

    // Generate new 6-digit OTP
    final newOtp = (100000 + Random().nextInt(900000)).toString();
    _currentOtp = newOtp;

    final String? errorMsg = await EmailService.sendOtpEmail(
      userEmail: widget.email,
      otpCode: newOtp,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (errorMsg == null) {
        showInfoDialog(
          context: context,
          title: 'Code Sent',
          message: 'A new verification code has been sent to ${widget.email}.',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        );
      } else {
        showInfoDialog(
          context: context,
          title: 'Email Delivery Error',
          message: 'Failed to send verification code. Details: ${ErrorHandler.getErrorMessage(errorMsg)}',
          icon: Icons.error_outline,
          iconColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2-Step Verification'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 80.w,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: 24.h),
                Text(
                  'Verify Your Identity',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  'We have sent a 6-digit verification code to:\n${widget.email}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48.h),
                AuthTextFieldWithIcon(
                  label: 'Verification Code',
                  hint: 'Enter 6-digit code',
                  controller: _otpController,
                  icon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the verification code';
                    }
                    if (value.trim().length != 6) {
                      return 'Code must be 6 digits';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32.h),
                AuthButton(
                  text: 'Verify',
                  onPressed: _verifyOtp,
                  isLoading: _isLoading,
                  height: 56,
                ),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _resendOtp,
                      child: Text(
                        'Resend',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
