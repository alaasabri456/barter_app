// ignore_for_file: deprecated_member_use

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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onFabPressed() {
    Navigator.pushNamed(context, RoutesManager.createProduct);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tabs[selectedIndex],
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  BottomAppBar _buildBottomAppBar() {
    return BottomAppBar(
      height: 70,
      color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
      elevation: 8,
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
            icon: selectedIndex == 1 ? Icons.list : Icons.list_outlined,
            label: 'Items',
            isSelected: selectedIndex == 1,
            onTap: () => _onTap(1),
          ),
          // Integrated FAB
          _buildFloatingActionButton(),
          _buildNavItem(
            icon: selectedIndex == 2
                ? Icons.swap_horiz
                : Icons.swap_horiz_outlined,
            label: 'Trades',
            isSelected: selectedIndex == 2,
            onTap: () => _onTap(2),
          ),
          _buildNavItem(
            icon: selectedIndex == 3 ? Icons.person : Icons.person_outline,
            label: 'Profile',
            isSelected: selectedIndex == 3,
            onTap: () => _onTap(3),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final selectedColor = const Color(0xFF25E4DA);
    final unselectedColor = Colors.grey.shade500;

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
    return GestureDetector(
      onTap: _onFabPressed,
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              const Color(0xFF25E4DA), // Teal/Blue from left
              const Color(0xFFE91E63), // Pink from right
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  void _onTap(int newIndex) {
    setState(() {
      selectedIndex = newIndex;
    });
  }
}
