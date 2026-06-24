import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/routes_manager/routes_manager.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/user_model.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../../../services/push_notification_service.dart';
import '../../../core/error/error_handler.dart';

class PhoneOtpScreen extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const PhoneOtpScreen({
    super.key,
    required this.arguments,
  });

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  late String _name;
  late String _email;
  late String _password;
  late String _phoneNumber;
  late String _verificationId;
  int? _resendToken;

  bool _isLoading = false;
  int _cooldownSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _name = widget.arguments['name'] as String;
    _email = widget.arguments['email'] as String;
    _password = widget.arguments['password'] as String;
    _phoneNumber = widget.arguments['phoneNumber'] as String;
    _verificationId = widget.arguments['verificationId'] as String;
    _resendToken = widget.arguments['resendToken'] as int?;

    _startCooldown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() {
      _cooldownSeconds = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }


  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    User? firebaseUser;
    try {
      final authViewModel = context.read<AuthViewModel>();
      final smsCode = _otpController.text.trim();

      // Create Phone Auth credential
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );

      // Create email/password user first
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Link with the phone credential to verify phone number and add it to auth profile
        await firebaseUser.linkWithCredential(credential);

        // Check if user is whitelisted as admin
        final isWhitelisted = await authViewModel.isEmailWhitelistedAsAdmin(_email);
        final role = isWhitelisted ? UserRole.admin : UserRole.user;

        // Create the user document in Firestore
        final newUser = UserModel(
          id: firebaseUser.uid,
          name: _name,
          email: _email,
          favouriteProductIds: [],
          role: role,
          phoneNumber: _phoneNumber,
        );

        await authViewModel.addUserToFireStore(newUser);

        // Set current user & listener
        UserModel.currentUser = newUser;
        authViewModel.initUserListener();

        // Update notification token
        await PushNotificationService.updateToken();

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          // Show brief success checkmark dialog
          await showInfoDialog(
            context: context,
            title: 'Registration Successful',
            message: 'Your account has been created and verified!',
            icon: Icons.check_circle_outlined,
            iconColor: Colors.green,
          );

          // Navigate to main layout and clear history
          Navigator.of(context).pushNamedAndRemoveUntil(
            RoutesManager.mainLayout,
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Clean up newly created email user if linking failed
      if (firebaseUser != null) {
        try {
          await firebaseUser.delete();
        } catch (cleanupError) {
          debugPrint('Failed to clean up user after link failure: $cleanupError');
        }
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        String errorMessage = ErrorHandler.getErrorMessage(e);
        showInfoDialog(
          context: context,
          title: 'Verification Failed',
          message: errorMessage,
          icon: Icons.error_outline,
          iconColor: Theme.of(context).colorScheme.error,
        );
      }
    } catch (e) {
      // Clean up newly created email user if linking/firestore write failed
      if (firebaseUser != null) {
        try {
          await firebaseUser.delete();
        } catch (cleanupError) {
          debugPrint('Failed to clean up user after Firestore/general failure: $cleanupError');
        }
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        showInfoDialog(
          context: context,
          title: 'Error',
          message: ErrorHandler.getErrorMessage(e),
          icon: Icons.error_outline,
          iconColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authViewModel = context.read<AuthViewModel>();

      await authViewModel.sendPhoneOtp(
        phoneNumber: _phoneNumber,
        forceResendingToken: _resendToken,
        onCodeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
            _verificationId = verificationId;
            _resendToken = resendToken;
          });
          _startCooldown();
          if (mounted) {
            showInfoDialog(
              context: context,
              title: 'SMS Sent',
              message: 'A new code has been sent to $_phoneNumber.',
              icon: Icons.sms_outlined,
              iconColor: Colors.green,
            );
          }
        },
        onVerificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            String errorMessage = ErrorHandler.getErrorMessage(e);
            showInfoDialog(
              context: context,
              title: 'Resend Failed',
              message: errorMessage,
              icon: Icons.error_outline,
              iconColor: Theme.of(context).colorScheme.error,
            );
          }
        },
        onAutoVerified: (PhoneAuthCredential credential) {
          // Handle auto-verification if needed
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showInfoDialog(
          context: context,
          title: 'Error',
          message: ErrorHandler.getErrorMessage(e),
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
        title: const Text('Phone Verification'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                  Icons.phone_android_outlined,
                  size: 80.w,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: 24.h),
                Text(
                  'Verify Your Phone',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  'We sent a 6-digit SMS verification code to:\n$_phoneNumber',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48.h),
                AuthTextFieldWithIcon(
                  label: 'SMS Code',
                  hint: 'Enter 6-digit SMS code',
                  controller: _otpController,
                  icon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the SMS code';
                    }
                    if (value.trim().length != 6) {
                      return 'Code must be exactly 6 digits';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32.h),
                AuthButton(
                  text: 'Verify & Register',
                  onPressed: _isLoading ? null : _verifyOtp,
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
                      onPressed: (_isLoading || _cooldownSeconds > 0) ? null : _resendOtp,
                      child: Text(
                        _cooldownSeconds > 0 ? 'Resend in $_cooldownSeconds s' : 'Resend',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: (_isLoading || _cooldownSeconds > 0)
                              ? Theme.of(context).disabledColor
                              : Theme.of(context).primaryColor,
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
