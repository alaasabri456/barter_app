// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/routes_manager/routes_manager.dart';
import '../../firebase/firebase_service.dart';
import '../../features/authentication/models/user_model.dart';
import '../../core/widgets/loading_widget.dart';
import '../../services/push_notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _startSplashSequence();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startSplashSequence() async {
    // Start animations
    _animationController.forward();

    // Wait for minimum splash duration
    await Future.delayed(const Duration(seconds: 2));

    // Check authentication state
    await _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // User is signed in, get user data
        UserModel.currentUser = await FirebaseService.getUserFromFireStore(
          currentUser.uid,
        );

        if (UserModel.currentUser == null && currentUser.isAnonymous) {
          UserModel.currentUser = UserModel.guest(currentUser.uid);
        }

        // Update FCM token once user is available
        await PushNotificationService.updateToken();

        if (mounted) {
          _navigateToMainLayout();
        }
      } else {
        // User is not signed in
        if (mounted) {
          _navigateToAuth();
        }
      }
    } catch (e) {
      // Error occurred, navigate to auth
      if (mounted) {
        _navigateToAuth();
      }
    }
  }

  void _navigateToMainLayout() {
    // ProductModel mockProduct=ProductModel(id: "", title: "TEST", description: "FFF", category: "sports", condition: "good", ownerId: "", ownerName: "alaa", images: [], createdAt: DateTime.now(), updatedAt: DateTime.now());
    Navigator.of(context).pushReplacementNamed(RoutesManager.mainLayout);
    // Navigator.pushNamed(
    //   context,
    //   RoutesManager.tradeManagement,
    //    // You need to provide a ProductModel
    // );
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacementNamed(RoutesManager.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo section
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // App icon/logo
                              Container(
                                width: 150.w,
                                height: 150.w,
                                padding: EdgeInsets.all(20.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),

                              SizedBox(
                                height: 24.h,
                              ), // Spacing after logo, before tagline

                              SizedBox(height: 8.h),

                              // App tagline
                              Text(
                                'Trade. Share. Connect.',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Loading section
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(
                                0.6,
                                1.0,
                                curve: Curves.easeIn,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              const LoadingWidget(
                                color: Colors.white,
                                size: 32,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Version info
              Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 0.7).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
                        ),
                      ),
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  late Animation<double> _logoRotation;
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

    _logoRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _textSlide = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _startAnimations();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _startAnimations() async {
    _rippleController.repeat();

    await Future.delayed(const Duration(milliseconds: 500));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 2000));

    if (mounted) {
      await _checkAuthAndNavigate();
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        UserModel.currentUser = await FirebaseService.getUserFromFireStore(
          currentUser.uid,
        );

        if (UserModel.currentUser == null && currentUser.isAnonymous) {
          UserModel.currentUser = UserModel.guest(currentUser.uid);
        }

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
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ripple effect
              AnimatedBuilder(
                animation: _rippleController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ripple
                      Transform.scale(
                        scale: _rippleAnimation.value * 2,
                        child: Container(
                          width: 200.w,
                          height: 200.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(
                                0.3 * (1 - _rippleAnimation.value),
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      // Inner ripple
                      Transform.scale(
                        scale: _rippleAnimation.value * 1.5,
                        child: Container(
                          width: 150.w,
                          height: 150.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(
                                0.5 * (1 - _rippleAnimation.value),
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      // Logo
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScale.value,
                            child: Transform.rotate(
                              angle: _logoRotation.value * 0.5,
                              child: Container(
                                width: 100.w,
                                height: 100.w,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(15.w),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
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

              SizedBox(height: 40.h),

              // App text
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _textSlide.value),
                    child: Opacity(
                      opacity: _textController.value,
                      child: Column(
                        children: [
                          // Text(
                          //   'Barter',
                          //   style: TextStyle(
                          //     fontSize: 42.sp,
                          //     fontWeight: FontWeight.bold,
                          //     color: Colors.white,
                          //     letterSpacing: 3,
                          //   ),
                          // ),
                          SizedBox(height: 8.h),

                          Text(
                            'Trade. Share. Connect.',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 1.5,
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
      ),
    );
  }
}
