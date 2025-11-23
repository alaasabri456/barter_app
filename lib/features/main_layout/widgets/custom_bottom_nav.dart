import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'bottom_nav_item.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                            size: 24.w,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}



class AnimatedBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final Duration animationDuration;
  final Curve curve;

  const AnimatedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.animationDuration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
  });

  @override
  State<AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<AnimatedBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.items.length,
          (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: widget.curve),
      );
    }).toList();

    // Start animation for current index
    _controllers[widget.currentIndex].forward();
  }

  @override
  void didUpdateWidget(AnimatedBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controllers[oldWidget.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == widget.currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedBuilder(
                    animation: _animations[index],
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _animations[index].value,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(
                                      isSelected ? item.activeIcon : item.icon,
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                                      size: 24.w,
                                    ),
                                  ),
                                  if (item.badgeCount != null && item.badgeCount! > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: EdgeInsets.all(4.w),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.error,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: 16.w,
                                          minHeight: 16.w,
                                        ),
                                        child: Text(
                                          item.badgeCount! > 99 ? '99+' : '${item.badgeCount}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}