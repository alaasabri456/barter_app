// ignore_for_file: deprecated_member_use

import 'package:barter/features/home/home_screen.dart';
import 'package:barter/features/chat/chat_list_screen.dart';
import 'package:barter/features/profile/profile_screen.dart';
import 'package:barter/features/trade/trade_management_screen.dart';
import 'package:flutter/material.dart';

import '../../core/routes_manager/routes_manager.dart';
import '../authentication/models/user_model.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../core/resources/colors_manager.dart';
import 'package:barter/l10n/app_localizations.dart';
import '../create_product/widgets/create_offer_popup.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  List<Widget> tabs = [
    HomeScreen(),
    ChatListScreen(),
    TradeManagementScreen(),
    ProfileScreen(),
  ];
  int selectedIndex = 0;

  void _onFabPressed() {
    if (UserModel.isGuest) {
      _showGuestLoginPrompt();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => CreateOfferPopup(
        onSelect: (type) {
          Navigator.pop(context); // Close popup
          Navigator.pushNamed(
            context,
            RoutesManager.createProduct,
            arguments: type,
          );
        },
      ),
    );
  }

  void _showGuestLoginPrompt() {
    showConfirmationDialog(
      context: context,
      title: 'Sign In Required',
      message: 'You need to sign in to access this feature.',
      confirmText: 'Sign In',
      cancelText: 'Maybe Later',
      icon: Icons.login,
    ).then((value) {
      if (value == true && mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RoutesManager.login, (route) => false);
      }
    });
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
            label: AppLocalizations.of(context)!.home,
            isSelected: selectedIndex == 0,
            onTap: () => _onTap(0),
          ),
          _buildNavItem(
            icon: selectedIndex == 1 ? Icons.chat : Icons.chat_outlined,
            label: AppLocalizations.of(context)!.chats,
            isSelected: selectedIndex == 1,
            onTap: () => _onTap(1),
          ),
          // Integrated FAB
          _buildFloatingActionButton(),
          _buildNavItem(
            icon: selectedIndex == 2
                ? Icons.swap_horiz
                : Icons.swap_horiz_outlined,
            label: AppLocalizations.of(context)!.trades,
            isSelected: selectedIndex == 2,
            onTap: () => _onTap(2),
          ),
          _buildNavItem(
            icon: selectedIndex == 3 ? Icons.person : Icons.person_outline,
            label: AppLocalizations.of(context)!.profile,
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
    final selectedColor = Theme.of(context).primaryColor;
    final unselectedColor = ColorsManager.grey500;

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
          gradient: ColorsManager.primaryGradient,
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
    if (UserModel.isGuest && (newIndex == 1 || newIndex == 2)) {
      _showGuestLoginPrompt();
      return;
    }
    setState(() {
      selectedIndex = newIndex;
    });
  }
}
