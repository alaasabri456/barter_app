import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/routes_manager/routes_manager.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../firebase/firebase_service.dart';
import '../../../models/login_request.dart';
import '../../../models/user_model.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final loginRequest = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Sign in with Firebase Auth
      final UserCredential userCredential = await FirebaseService.login(loginRequest);

      if (userCredential.user != null) {
        // Get user data from Firestore
        UserModel.currentUser = await FirebaseService.getUserFromFireStore(
          userCredential.user!.uid,
        );

        if (mounted) {
          // Navigate to main layout
          Navigator.of(context).pushNamedAndRemoveUntil(
            RoutesManager.mainLayout,
                (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = _getErrorMessage(e.code);
        await showInfoDialog(
          context: context,
          title: 'Login Failed',
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
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).pushNamed(RoutesManager.register);
  }

  void _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      await showInfoDialog(
        context: context,
        title: 'Email Required',
        message: 'Please enter your email address first.',
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Password Reset',
          message: 'Password reset email sent. Please check your inbox.',
          icon: Icons.email_outlined,
        );
      }
    } catch (e) {
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Error',
          message: 'Failed to send reset email. Please try again.',
          icon: Icons.error_outline,
          iconColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 60.h),

                // Welcome back text
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                Text(
                  'Sign in to continue to Barter',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 48.h),

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
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _login,
                ),

                SizedBox(height: 16.h),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: LinkButton(
                    text: 'Forgot Password?',
                    onPressed: _forgotPassword,
                    fontSize: 14.sp,
                  ),
                ),

                SizedBox(height: 32.h),

                // Login button
                AuthButton(
                  text: 'Sign In',
                  onPressed: _login,
                  isLoading: _isLoading,
                  height: 56,
                ),

                SizedBox(height: 24.h),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                SizedBox(height: 24.h),

                // Register option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    LinkButton(
                      text: 'Sign Up',
                      onPressed: _navigateToRegister,
                      fontSize: 14.sp,
                    ),
                  ],
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}