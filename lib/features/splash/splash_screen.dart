// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/routes_manager/routes_manager.dart';
import 'package:provider/provider.dart';
import '../authentication/viewmodels/auth_viewmodel.dart';
import '../../features/authentication/models/user_model.dart';
import '../../services/push_notification_service.dart';
import '../../core/resources/colors_manager.dart';
import 'package:barter/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _startSplashSequence();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startSplashSequence() async {
    _animationController.forward();
    await Future.delayed(const Duration(seconds: 2));
    await _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        final authViewModel = context.read<AuthViewModel>();
        UserModel.currentUser = await authViewModel.getUserFromFireStore(
          currentUser.uid,
        );
        authViewModel.initUserListener();

        if (UserModel.currentUser == null && currentUser.isAnonymous) {
          UserModel.currentUser = UserModel.guest(currentUser.uid);
        }

        await PushNotificationService.updateToken();

        if (mounted) {
          Navigator.of(context).pushReplacementNamed(RoutesManager.mainLayout);
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(RoutesManager.login);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(RoutesManager.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AnimatedSplashScreen();
  }
}

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _rippleController;

  late Animation<double> _logoScale;
  late Animation<double> _textSlide;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textSlide = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _rippleController.repeat();
    _logoController.forward();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _textController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: ColorsManager.primaryGradient,
        ),
        child: Stack(
          children: [
            // Decorative floating shapes
            Positioned(
              top: -100.h,
              right: -50.w,
              child:
                  _buildDecorativeCircle(250.w, Colors.white.withOpacity(0.1)),
            ),
            Positioned(
              bottom: -80.h,
              left: -60.w,
              child:
                  _buildDecorativeCircle(200.w, Colors.white.withOpacity(0.1)),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo Section
                  AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse effect
                          _buildRippleCircle(_rippleAnimation.value * 2.2,
                              0.2 * (1 - _rippleAnimation.value)),
                          _buildRippleCircle(_rippleAnimation.value * 1.7,
                              0.4 * (1 - _rippleAnimation.value)),

                          // Glass Logo Container
                          AnimatedBuilder(
                            animation: _logoController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _logoScale.value,
                                child: Container(
                                  width: 140.w,
                                  height: 140.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(25.w),
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 50.h),

                  // App Name and Tagline
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textController.value,
                        child: Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Column(
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .appName
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 36.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                AppLocalizations.of(context)!.tagline,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Version info at bottom
            Positioned(
              bottom: 30.h,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.version('1.0.0'),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRippleCircle(double scale, double opacity) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 150.w,
        height: 150.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(opacity),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
