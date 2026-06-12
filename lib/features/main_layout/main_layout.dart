// ignore_for_file: deprecated_member_use

import 'package:barter/features/home/home_screen.dart';
import 'package:barter/features/chat/chat_list_screen.dart';
import 'package:barter/features/profile/profile_screen.dart';
import 'package:barter/features/trade/trade_management_screen.dart';
import 'package:barter/features/admin/screens/admin_dashboard_screen.dart';
import 'package:barter/features/delivery/screens/agent_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../chat/viewmodels/chat_viewmodel.dart';

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
  late List<Widget> tabs;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initTabs();
  }

  void _initTabs() {
    final user = UserModel.currentUser;
    if (user != null && user.isAdmin) {
      tabs = [
        AdminDashboardScreen(),
        ChatListScreen(),
        ProfileScreen(),
      ];
    } else if (user != null && user.isAgent) {
      tabs = [
        AgentDashboardScreen(),
        ChatListScreen(),
        ProfileScreen(),
      ];
    } else {
      tabs = [
        HomeScreen(),
        ChatListScreen(),
        TradeManagementScreen(),
        ProfileScreen(),
      ];
    }
  }

  bool get _isRegularUser {
    final user = UserModel.currentUser;
    if (user == null) return true; // Guest
    return !user.isAdmin && !user.isAgent;
  }

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
      body: IndexedStack(
        index: selectedIndex,
        children: tabs,
      ),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildBottomAppBar() {
    final user = UserModel.currentUser;
    if (user == null || user.isAnonymous) {
      return _buildBottomAppBarContent(0);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: context.read<ChatViewModel>().getUserConversations(user.id),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final count = data['unreadCount_${user.id}'] as int? ?? 0;
            unreadCount += count;
          }
        }
        return _buildBottomAppBarContent(unreadCount);
      },
    );
  }

  BottomAppBar _buildBottomAppBarContent(int unreadCount) {
    return BottomAppBar(
      height: 70,
      color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
      elevation: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _isRegularUser 
            ? _buildRegularUserNavItems(unreadCount) 
            : _buildRoleNavItems(unreadCount),
      ),
    );
  }

  List<Widget> _buildRegularUserNavItems(int unreadCount) {
    return [
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
        badgeCount: unreadCount,
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
    ];
  }

  List<Widget> _buildRoleNavItems(int unreadCount) {
    final isAgent = UserModel.currentUser?.isAgent ?? false;
    
    return [
      _buildNavItem(
        icon: selectedIndex == 0 ? Icons.dashboard : Icons.dashboard_outlined,
        label: isAgent ? 'Agent' : 'Admin',
        isSelected: selectedIndex == 0,
        onTap: () => _onTap(0),
      ),
      _buildNavItem(
        icon: selectedIndex == 1 ? Icons.chat : Icons.chat_outlined,
        label: AppLocalizations.of(context)!.chats,
        isSelected: selectedIndex == 1,
        badgeCount: unreadCount,
        onTap: () => _onTap(1),
      ),
      _buildNavItem(
        icon: selectedIndex == 2 ? Icons.person : Icons.person_outline,
        label: AppLocalizations.of(context)!.profile,
        isSelected: selectedIndex == 2,
        onTap: () => _onTap(2),
      ),
    ];
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final selectedColor = Theme.of(context).primaryColor;
    final unselectedColor = ColorsManager.grey500;

    Widget iconWidget = Icon(
      icon,
      color: isSelected ? selectedColor : unselectedColor,
      size: 24,
    );

    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text(badgeCount > 99 ? '99+' : badgeCount.toString()),
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 70),
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
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
    if (_isRegularUser) {
      if (UserModel.isGuest && (newIndex == 1 || newIndex == 2)) {
        _showGuestLoginPrompt();
        return;
      }
    } else {
      // For Admins and Agents, newIndex == 1 is Chats (no login prompt needed as they are logged in)
    }
    setState(() {
      selectedIndex = newIndex;
    });
  }
}
