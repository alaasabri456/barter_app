import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/routes_manager/routes_manager.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../firebase/firebase_service.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../../../services/push_notification_service.dart';
import 'dart:math';
import '../../../services/email_service.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      await showInfoDialog(
        context: context,
        title: 'Terms Required',
        message:
            'Please agree to the Terms of Service and Privacy Policy to continue.',
        icon: Icons.warning_outlined,
        iconColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ── Step 1: Check if email is already registered ──
      final email = _emailController.text.trim();
      bool emailAlreadyExists = false;
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: '##DUMMY_CHECK##',
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential' ||
            e.code == 'user-disabled') {
          emailAlreadyExists = true;
        }
        // 'user-not-found' or 'invalid-email' means the email is not registered
      }

      if (emailAlreadyExists) {
        if (mounted) {
          await showInfoDialog(
            context: context,
            title: 'Account Already Exists',
            message: 'An account with this email address already exists. Please sign in instead.',
            icon: Icons.person_off_outlined,
            iconColor: Theme.of(context).colorScheme.error,
          );
          setState(() { _isLoading = false; });
        }
        return;
      }

      // ── Step 2: Send OTP for email verification ──
      final newOtp = (100000 + Random().nextInt(900000)).toString();
      final errorMsg = await EmailService.sendOtpEmail(
        userEmail: email,
        otpCode: newOtp,
      );

      setState(() {
        _isLoading = false;
      });

      if (errorMsg != null) {
        if (mounted) {
          await showInfoDialog(
            context: context,
            title: 'Email Delivery Error',
            message: 'Failed to send verification email. Details: $errorMsg',
            icon: Icons.error_outline,
            iconColor: Theme.of(context).colorScheme.error,
          );
        }
        return;
      }

      if (mounted) {
        final verified = await _showOtpDialog(newOtp);
        if (verified != true) return;
      }

      setState(() {
        _isLoading = true;
      });

      final registerRequest = RegisterRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Create user with Firebase Auth
      final UserCredential userCredential = await FirebaseService.register(
        registerRequest,
      );

      if (userCredential.user != null) {
        // Check if user is whitelisted as admin
        final isWhitelisted = await FirebaseService.isEmailWhitelistedAsAdmin(email);
        final role = isWhitelisted ? UserRole.admin : UserRole.user;

        // Create user document in Firestore
        final newUser = UserModel(
          id: userCredential.user!.uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          favouriteProductIds: [],
          role: role,
        );

        await FirebaseService.addUserToFireStore(newUser);

        // Set current user
        UserModel.currentUser = newUser;

        // Update FCM token on register
        await PushNotificationService.updateToken();

        if (mounted) {
          // Show success message
          await showInfoDialog(
            context: context,
            title: 'Account Created',
            message: 'Your account has been created successfully!',
            icon: Icons.check_circle_outlined,
            iconColor: Colors.green,
          );

          // Navigate to main layout
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(RoutesManager.mainLayout, (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = _getErrorMessage(e.code);
        await showInfoDialog(
          context: context,
          title: 'Registration Failed',
          message: errorMessage,
          icon: Icons.error_outline,
          iconColor: Theme.of(context).colorScheme.error,
        );
      }
    } catch (e) {
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Error',
          message: 'An unexpected error occurred. Please try again.',
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

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  Future<bool?> _showOtpDialog(String expectedOtp) async {
    final otpController = TextEditingController();
    final localFormKey = GlobalKey<FormState>();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Verify Email'),
          content: Form(
            key: localFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('We sent a 6-digit code to ${_emailController.text.trim()}.\nPlease enter it below to verify your email.'),
                SizedBox(height: 16.h),
                AuthTextFieldWithIcon(
                  label: 'Verification Code',
                  hint: 'Enter 6-digit code',
                  controller: otpController,
                  icon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the code';
                    }
                    if (value.trim() != expectedOtp) {
                      return 'Incorrect code';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (localFormKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pop();
  }

  void _showTermsAndConditions() async {
    await showCustomBottomSheet(
      context: context,
      title: 'Terms of Service',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms of Service',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Text(
            '1. Acceptance of Terms',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Text(
            'By using Barter, you agree to these terms and conditions.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16.h),
          Text(
            '2. User Responsibilities',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Text(
            'Users are responsible for the accuracy of their listings and must engage in fair trading practices.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16.h),
          Text(
            '3. Privacy Policy',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Text(
            'We respect your privacy and protect your personal information in accordance with our Privacy Policy.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        Expanded(
          child: AuthButton(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color,
          ),
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
                SizedBox(height: 20.h),

                // Create account text
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                Text(
                  'Sign up to start bartering with others',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 32.h),

                // Name field
                AuthTextFieldWithIcon(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  icon: Icons.person_outline,
                  validator: Validators.validateName,
                  textInputAction: TextInputAction.next,
                ),

                SizedBox(height: 24.h),

                // Email field
                AuthTextFieldWithIcon(
                  label: 'Email Address',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_outlined,
                  validator: Validators.validateEmail,
                  textInputAction: TextInputAction.next,
                ),

                SizedBox(height: 24.h),

                // Password field
                AuthTextFieldWithIcon(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: Validators.validatePassword,
                  textInputAction: TextInputAction.next,
                ),

                SizedBox(height: 24.h),

                // Confirm Password field
                AuthTextFieldWithIcon(
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  controller: _confirmPasswordController,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _register,
                ),

                SizedBox(height: 24.h),

                // Terms checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreeToTerms = !_agreeToTerms;
                          });
                        },
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodySmall,
                            children: [
                              TextSpan(text: 'I agree to the '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: _showTermsAndConditions,
                                  child: Text(
                                    'Terms of Service',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      decoration: TextDecoration.underline,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ),
                              TextSpan(text: ' and '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: _showTermsAndConditions,
                                  child: Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      decoration: TextDecoration.underline,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32.h),

                // Register button
                AuthButton(
                  text: 'Create Account',
                  onPressed: _register,
                  isLoading: _isLoading,
                  height: 56,
                ),

                SizedBox(height: 24.h),

                // Login option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    LinkButton(
                      text: 'Sign In',
                      onPressed: _navigateToLogin,
                      fontSize: 14.sp,
                    ),
                  ],
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
