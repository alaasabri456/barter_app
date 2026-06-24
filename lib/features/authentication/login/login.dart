// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/routes_manager/routes_manager.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/custom_dialog.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/login_request.dart';
import '../models/user_model.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import 'dart:math';
import '../../../services/email_service.dart';
import '../../../services/push_notification_service.dart';
import 'package:barter/l10n/app_localizations.dart';

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
  // ignore: unused_field, prefer_final_fields
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
      final authViewModel = context.read<AuthViewModel>();
      final UserCredential? userCredential = await authViewModel.login(
        loginRequest,
      );

      if (userCredential != null && userCredential.user != null) {

        if (UserModel.currentUser != null && UserModel.currentUser!.is2faEnabled) {
          final newOtp = (100000 + Random().nextInt(900000)).toString();
          
          final String? errorMsg = await EmailService.sendOtpEmail(
            userEmail: UserModel.currentUser!.email,
            otpCode: newOtp,
          );

          if (mounted) {
            if (errorMsg == null) {
              Navigator.of(context).pushNamed(
                RoutesManager.otpVerification,
                arguments: {
                  'email': UserModel.currentUser!.email,
                  'generatedOtp': newOtp,
                },
              );
            } else {
              await showInfoDialog(
                context: context,
                title: 'Email Delivery Error',
                message: 'Failed to send verification email. Details: $errorMsg',
                icon: Icons.error_outline,
                iconColor: Theme.of(context).colorScheme.error,
              );
            }
          }
          } else if (UserModel.currentUser != null) {
            // Update FCM token on login
            await PushNotificationService.updateToken();

            if (mounted) {
              // Navigate based on user role
              switch (UserModel.currentUser!.role) {
                case UserRole.admin:
                  Navigator.of(context).pushNamedAndRemoveUntil(RoutesManager.adminDashboard, (route) => false);
                  break;
                case UserRole.agent:
                  Navigator.of(context).pushNamedAndRemoveUntil(RoutesManager.agentDashboard, (route) => false);
                  break;
                default:
                  Navigator.of(context).pushNamedAndRemoveUntil(RoutesManager.mainLayout, (route) => false);
              }
            }
          }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Login Failed',
          message: ErrorHandler.getErrorMessage(e),
          icon: Icons.error_outline,
          iconColor: Theme.of(context).colorScheme.error,
        );
      }
    } catch (e) {
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Error',
          message: ErrorHandler.getErrorMessage(e),
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authViewModel = context.read<AuthViewModel>();
      final userCredential = await authViewModel.signInWithGoogle();
      final user = userCredential?.user;

      if (user != null) {

        if (UserModel.currentUser?.is2faEnabled == true)  {
          final newOtp = (100000 + Random().nextInt(900000)).toString();
          
          final String? errorMsg = await EmailService.sendOtpEmail(
            userEmail: UserModel.currentUser!.email,
            otpCode: newOtp,
          );

          if (mounted) {
            if (errorMsg == null) {
              Navigator.of(context).pushNamed(
                RoutesManager.otpVerification,
                arguments: {
                  'email': UserModel.currentUser!.email,
                  'generatedOtp': newOtp,
                },
              );
            } else {
              await showInfoDialog(
                context: context,
                title: 'Email Delivery Error',
                message: 'Failed to send verification email. Details: $errorMsg',
                icon: Icons.error_outline,
                iconColor: Theme.of(context).colorScheme.error,
              );
            }
          }
        } else {
          await PushNotificationService.updateToken();
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(RoutesManager.mainLayout, (route) => false);
          }
        }
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      if (mounted) {
        String errorMessage = e.toString();
        if (!errorMessage.contains('aborted') &&
            !errorMessage.contains('canceled')) {
          showInfoDialog(
            context: context,
            title: 'Sign In Failed',
            message: ErrorHandler.getErrorMessage(e),
            icon: Icons.error_outline,
            iconColor: Theme.of(context).colorScheme.error,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Centralized error handling used instead of local _getErrorMessage

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
                  AppLocalizations.of(context)!.welcomeBack,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                Text(
                  AppLocalizations.of(context)!.signInSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 48.h),



                // Email field
                AuthTextFieldWithIcon(
                  label: AppLocalizations.of(context)!.emailLabel,
                  hint: AppLocalizations.of(context)!.emailHint,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_outlined,
                  validator: Validators.validateEmail,
                  textInputAction: TextInputAction.next,
                ),

                SizedBox(height: 24.h),

                // Password field
                AuthTextFieldWithIcon(
                  label: AppLocalizations.of(context)!.passwordLabel,
                  hint: AppLocalizations.of(context)!.passwordHint,
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
                    text: AppLocalizations.of(context)!.forgotPassword,
                    onPressed: _forgotPassword,
                    fontSize: 14.sp,
                  ),
                ),

                SizedBox(height: 32.h),

                // Login button
                AuthButton(
                  text: AppLocalizations.of(context)!.signIn,
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
                        AppLocalizations.of(context)!.orDivider,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color?.withOpacity(0.6),
                            ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                SizedBox(height: 24.h),

                // Google Sign In
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      side: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                      ),
                    ),
                    icon: Icon(Icons.login_outlined),
                    label: Text(
                      AppLocalizations.of(context)!.signInWithGoogle,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Register option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${AppLocalizations.of(context)!.dontHaveAccount} ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    LinkButton(
                      text: AppLocalizations.of(context)!.signUp,
                      onPressed: _navigateToRegister,
                      fontSize: 14.sp,
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Continue as guest
                OutlinedButton(
                  onPressed: () async {
                    try {
                      final userCredential =
                          await FirebaseAuth.instance.signInAnonymously();
                      if (userCredential.user != null) {
                        UserModel.currentUser = UserModel.guest(
                          userCredential.user!.uid,
                        );
                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            RoutesManager.mainLayout,
                            (route) => false,
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to continue as guest: ${e.toString()}',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.continueAsGuest,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
