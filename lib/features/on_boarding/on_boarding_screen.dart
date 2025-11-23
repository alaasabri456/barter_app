import 'package:barter/features/on_boarding/onboarding_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/prefs_manager/prefs_manager.dart';
import '../../core/routes_manager/routes_manager.dart';
import '../authentication/widgets/auth_button.dart';


/// Widget for a single page in onboarding
class OnBoardingPageWidget extends StatelessWidget {
  final OnBoardingModel page;
  final bool animated;
  final Animation<double>? fade;
  final Animation<Offset>? slide;

  const OnBoardingPageWidget({
    super.key,
    required this.page,
    this.animated = false,
    this.fade,
    this.slide,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 60.w, color: page.color),
          ),
          SizedBox(height: 48.h),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    if (!animated) return content;

    return FadeTransition(opacity: fade!, child: SlideTransition(position: slide!, child: content));

  }
}

/// Reusable Onboarding Screen
class OnBoardingScreen extends StatefulWidget {
  final bool animated;

  const OnBoardingScreen({super.key, this.animated = false});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
    CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);


    if (widget.animated) {
    _animationController.reset();
    _animationController.forward();
    }


  }

  void _nextPage() {
    if (_currentIndex < onboardingPages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
    }
  }

  void _skipOnboarding() => _completeOnboarding();

  void _completeOnboarding() {
    PrefsManager.prefs.setBool('onboardingCompleted', true);
    Navigator.of(context).pushReplacementNamed(RoutesManager.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                onboardingPages[_currentIndex].color.withOpacity(0.1),
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
                children: [
// Progress indicator
            Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / onboardingPages.length,
                    backgroundColor: Theme.of(context).dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(onboardingPages[_currentIndex].color),
                  ),
                ),
                SizedBox(width: 16.w),
                Text('${_currentIndex + 1}/${onboardingPages.length}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),


      // PageView
      Expanded(
      child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: onboardingPages.length,
      itemBuilder: (context, index) {
    return OnBoardingPageWidget(
    page: onboardingPages[index],
    animated: widget.animated,
    fade: _fadeAnimation,
    slide: _slideAnimation,
    );
    },
    ),
    ),

    // Bottom buttons & dots
    Padding(
    padding: EdgeInsets.all(24.w),
    child: Column(
    children: [
    Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(onboardingPages.length, (index) {
    return AnimatedContainer(
    duration: const Duration(milliseconds: 400),
    width: _currentIndex == index ? 32.w : 8.w,
    height: 8.h,
    margin: EdgeInsets.symmetric(horizontal: 4.w),
    decoration: BoxDecoration(
    color: _currentIndex == index ? onboardingPages[_currentIndex].color : Colors.grey.shade300,
    borderRadius: BorderRadius.circular(4.r),
    ),
    );
    }),
    ),
    SizedBox(height: 32.h),
    Row(
    children: [
    if (_currentIndex > 0)
    Expanded(
    child: AuthButton(
    text: 'Previous',
    onPressed: _previousPage,
    isOutlined: true,
    height: 56,
    ),
    ),
    if (_currentIndex > 0) SizedBox(width: 16.w),
    Expanded(
    flex: _currentIndex > 0 ? 1 : 2,
    child: AuthButton(
    text: _currentIndex < onboardingPages.length - 1 ? 'Next' : 'Start Trading',
    onPressed: _nextPage,
    backgroundColor: onboardingPages[_currentIndex].color,
    height: 56,
    ),
    ),
    ],
    ),
    if (_currentIndex < onboardingPages.length - 1)
    TextButton(
    onPressed: _skipOnboarding,
    child: Text('Skip for now', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
    ),
    ],
    ),
    ),
    ],
    ),
    ),
    ),
    );


  }
}
