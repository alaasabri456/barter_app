import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/routes_manager/routes_manager.dart';
import '../authentication/widgets/auth_button.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToOnboarding() =>
      Navigator.of(context).pushNamed(RoutesManager.onboarding);

  void _navigateToLogin() =>
      Navigator.of(context).pushNamed(RoutesManager.login);

  void _navigateToRegister() =>
      Navigator.of(context).pushNamed(RoutesManager.register);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView( // FIX: smooth + overflow-free
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 40.h),

                  /// ---------- HERO SECTION ----------
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (_, child) => FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            Container(
                              width: 150.w,
                              height: 150.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.7),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 3,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.swap_horiz_rounded,
                                size: 80.w,
                                color: Colors.white,
                              ),
                            ),

                            SizedBox(height: 30.h),

                            Text(
                              "Welcome to Barter",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: 12.h),

                            Text(
                              "Trade items you no longer need for things you want. Connect with your community.",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                height: 1.5,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color
                                    ?.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  /// ---------- FEATURES SECTION ----------
                  _buildFeatureItem(
                    icon: Icons.swap_horizontal_circle_outlined,
                    title: 'Easy Trading',
                    description: 'Quick and secure item exchanges.',
                    color: Colors.blue,
                  ),
                  SizedBox(height: 20.h),

                  _buildFeatureItem(
                    icon: Icons.people_outline,
                    title: 'Community',
                    description: 'Connect with traders around you.',
                    color: Colors.green,
                  ),
                  SizedBox(height: 20.h),

                  _buildFeatureItem(
                    icon: Icons.eco_outlined,
                    title: 'Sustainable',
                    description: 'Help reduce waste by reusing items.',
                    color: Colors.orange,
                  ),

                  SizedBox(height: 40.h),

                  /// ---------- ACTION BUTTONS ----------
                  AuthButton(
                    text: "Get Started",
                    onPressed: _navigateToOnboarding,
                    height: 56,
                  ),

                  SizedBox(height: 14.h),

                  AuthButton(
                    text: "Sign In",
                    isOutlined: true,
                    onPressed: _navigateToLogin,
                    height: 56,
                  ),

                  SizedBox(height: 20.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: _navigateToRegister,
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(icon, color: color, size: 26.w),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
