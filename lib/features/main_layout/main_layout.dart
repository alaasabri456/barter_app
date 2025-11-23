import 'package:barter/features/main_layout/widgets/bottom_nav_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../home/home_screen.dart';
import '../products/products_screen.dart';
import '../create_product/create_product.dart';
import '../profile/profile_screen.dart';
import 'widgets/custom_bottom_nav.dart' ;


class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  late PageController _pageController;

  // Define the screens for each tab
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _screens = [
      const HomeScreen(),
      const ProductsScreen(),
      const CreateProduct(),
       const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _currentIndex = index;
    });

    // Animate to the selected page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // Define bottom navigation items
  final List<BottomNavItem> _navItems = [
    const BottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    const BottomNavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Products',
    ),
    const BottomNavItem(
      icon: Icons.add_circle_outline,
      activeIcon: Icons.add_circle,
      label: 'Create',
    ),
    const BottomNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe navigation
        children: _screens,
      ),
      bottomNavigationBar:
         AnimatedBottomNav(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: _navItems,
        ),

    );
  }
}

// Alternative implementation with standard BottomNavigationBar
class MainLayoutStandard extends StatefulWidget {
  const MainLayoutStandard({super.key});

  @override
  State<MainLayoutStandard> createState() => _MainLayoutStandardState();
}

class _MainLayoutStandardState extends State<MainLayoutStandard> {
  int _currentIndex = 0;

  // Define the screens for each tab
  final List<Widget> _screens = [
    const HomeScreen(),
     const ProductsScreen(),
    const CreateProduct(),
     const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Tab configuration class for better organization
class TabConfig {
  final Widget screen;
  final BottomNavItem navItem;
  final String title;
  final bool maintainState;

  const TabConfig({
    required this.screen,
    required this.navItem,
    required this.title,
    this.maintainState = true,
  });
}

// Advanced main layout with tab configuration
class MainLayoutAdvanced extends StatefulWidget {
  const MainLayoutAdvanced({super.key});

  @override
  State<MainLayoutAdvanced> createState() => _MainLayoutAdvancedState();
}

class _MainLayoutAdvancedState extends State<MainLayoutAdvanced>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late List<TabConfig> _tabs;

  @override
  void initState() {
    super.initState();

    _tabs = [
      TabConfig(
        screen:  const HomeScreen(),
        navItem: const BottomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Home',
        ),
        title: 'Home',
      ),
      TabConfig(
        screen:  const ProductsScreen(),
        navItem: const BottomNavItem(
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2,
          label: 'Products',
        ),
        title: 'My Products',
      ),
      TabConfig(
        screen: const CreateProduct(),
        navItem: const BottomNavItem(
          icon: Icons.add_circle_outline,
          activeIcon: Icons.add_circle,
          label: 'Create',
        ),
        title: 'Create Product',
      ),
      TabConfig(
        screen: const ProfileScreen(),
        navItem: const BottomNavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profile',
        ),
        title: 'Profile',
      ),
    ];
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    HapticFeedback.lightImpact();

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _tabs[_currentIndex].screen,
      ),
      bottomNavigationBar:
         CustomBottomNav(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: _tabs.map((tab) => tab.navItem).toList(),
        ),

    );
  }
}