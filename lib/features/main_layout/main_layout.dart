import 'package:barter/features/home/home_screen.dart';
import 'package:barter/features/products/products_screen.dart';
import 'package:barter/features/profile/profile_screen.dart';
import 'package:barter/features/trade/trade_management_screen.dart';
import 'package:flutter/material.dart';

import '../../core/routes_manager/routes_manager.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  List<Widget> tabs = [
    HomeScreen(),
    ProductsScreen(),
    TradeManagementScreen(),
    ProfileScreen(),
  ];
  int selectedIndex = 0;

  // Animation controllers for the FAB
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize rotation animation controller (on tap only)
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    // Initialize scale animation controller (on tap)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onFabPressed() {
    // Trigger rotation animation
    _rotationController.forward().then((_) {
      _rotationController.reset();
    });

    // Trigger scale animation
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    // Navigate after a brief delay
    Future.delayed(const Duration(milliseconds: 100), () {
      Navigator.pushNamed(context, RoutesManager.createProduct);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: tabs[selectedIndex],
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  BottomAppBar _buildBottomAppBar() {
    return BottomAppBar(
      notchMargin: 8,
      height: 70,
      color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
      shape: const CircularNotchedRectangle(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side - HOME and PRODUCTS
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                    label: 'HOME',
                    isSelected: selectedIndex == 0,
                    onTap: () => _onTap(0),
                  ),
                  _buildNavItem(
                    icon: selectedIndex == 1
                        ? Icons.inventory_2
                        : Icons.inventory_2_outlined,
                    label: 'Items',
                    isSelected: selectedIndex == 1,
                    onTap: () => _onTap(1),
                  ),
                ],
              ),
            ),

            // Empty space for FAB (center)
            SizedBox(width: 60),

            // Right side - TRADES and PROFILE
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: selectedIndex == 2
                        ? Icons.swap_horiz
                        : Icons.swap_horiz_outlined,
                    label: 'Trades',
                    isSelected: selectedIndex == 2,
                    onTap: () => _onTap(2),
                  ),
                  _buildNavItem(
                    icon: selectedIndex == 3
                        ? Icons.person
                        : Icons.person_outline,
                    label: 'Profile',
                    isSelected: selectedIndex == 3,
                    onTap: () => _onTap(3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context).bottomNavigationBarTheme;
    final selectedColor =
        theme.selectedItemColor ?? Theme.of(context).primaryColor;
    final unselectedColor = theme.unselectedItemColor ?? Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 70),
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? selectedColor : unselectedColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Animated rotating three-color circular border
                AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: CustomPaint(
                        size: Size(68, 68),
                        painter: _ThreeColorCirclePainter(),
                      ),
                    );
                  },
                ),
                // Inner white circle with icon (doesn't rotate)
                Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: Color(0xFF9E9E9E), size: 26),
                      onPressed: _onFabPressed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onTap(int newIndex) {
    setState(() {
      selectedIndex = newIndex;
    });
  }
}

// Custom painter for three-color circle border
class _ThreeColorCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 5.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Define three colors
    const color1 = Color(0xFF25E4DA); // Teal
    const color2 = Color(0xFFFFC425); // Orange
    const color3 = Color(0xFF3B77FE); // Blue

    // Draw three arcs (120 degrees each)
    const startAngle1 = -90.0 * 3.14159 / 180; // Top
    const startAngle2 = 30.0 * 3.14159 / 180; // Bottom right
    const startAngle3 = 150.0 * 3.14159 / 180; // Bottom left
    const sweepAngle = 120.0 * 3.14159 / 180;

    // First arc (Teal)
    paint.color = color1;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle1,
      sweepAngle,
      false,
      paint,
    );

    // Second arc (Orange)
    paint.color = color2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle2,
      sweepAngle,
      false,
      paint,
    );

    // Third arc (Blue)
    paint.color = color3;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle3,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
