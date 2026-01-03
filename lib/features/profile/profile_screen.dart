// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../firebase/firebase_service.dart';
import '../../core/routes_manager/routes_manager.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../features/authentication/models/user_model.dart';
import '../../core/theme/theme_provider.dart';
import '../authentication/widgets/auth_button.dart';
import '../../services/push_notification_service.dart';

import '../../features/trade/models/trade_offer.dart';
import '../reviews/reviews_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  int _createdProductsCount = 0;
  int _completedTradesCount = 0;
  int _reviewsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileStats();
  }

  Future<void> _loadProfileStats() async {
    final userId = UserModel.currentUser?.id;
    if (userId == null) return;

    try {
      // Load products count
      final products = await FirebaseService.getUserProducts(userId, context);

      // Load trades count
      final sentTrades = await FirebaseService.getSentTrades(userId);
      final receivedTrades = await FirebaseService.getReceivedTrades(userId);

      final completedTrades = [...sentTrades, ...receivedTrades]
          .where(
            (t) =>
                t.status == TradeStatus.accepted ||
                t.status == TradeStatus.completed,
          )
          .length;

      // Load reviews count
      final reviews = await FirebaseService.getUserReviews(userId);

      if (mounted) {
        setState(() {
          _createdProductsCount = products.length;
          _completedTradesCount = completedTrades;
          _reviewsCount = reviews.length;
        });
      }
    } catch (e) {
      // Silently fail or log error
      print('Error loading profile stats: $e');
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmText: 'Sign Out',
      cancelText: 'Cancel',
      icon: Icons.logout,
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signOut();
      UserModel.currentUser = null;

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RoutesManager.login, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        await showInfoDialog(
          context: context,
          title: 'Error',
          message: 'Failed to sign out. Please try again.',
          icon: Icons.error_outline,
          iconColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editProfile() {
    // Navigate to edit profile screen
    showInfoDialog(
      context: context,
      title: 'Coming Soon',
      message: 'Profile editing feature will be available soon!',
      icon: Icons.construction,
    );
  }

  void _showAbout() {
    showCustomBottomSheet(
      context: context,
      title: 'About Barter',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Barter App',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'A modern platform for trading and bartering goods with others in your community. Connect with people, discover interesting items, and make meaningful exchanges.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16.h),
          Text(
            '© 2024 Barter App. All rights reserved.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
      actions: [
        Expanded(
          child: AuthButton(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  Future<void> _sendTestNotification() async {
    var user = UserModel.currentUser;
    if (user?.fcmToken == null) {
      setState(() => _isLoading = true);
      await PushNotificationService.updateToken();
      user = UserModel.currentUser;
    }

    if (user == null || user.fcmToken == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('FCM Token not available')));
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseService.sendPushNotification(
        recipientToken: user.fcmToken!,
        title: 'Test Notification',
        body: 'Hello! This is a test push notification from Barter.',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Test notification sent!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send test: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _copyFcmToken() {
    final token = UserModel.currentUser?.fcmToken;
    if (token != null) {
      Clipboard.setData(ClipboardData(text: token));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('FCM Token copied to clipboard')));
    }
  }

  void _showPrivacyPolicy() {
    showCustomBottomSheet(
      context: context,
      title: 'Privacy Policy',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPolicySection(
            'Data Collection',
            'We collect information you provide directly to us, such as when you create an account, list a product, or contact us for support.',
          ),
          _buildPolicySection(
            'Data Usage',
            'We use your information to provide, maintain, and improve our services, process transactions, and communicate with you.',
          ),
          _buildPolicySection(
            'Data Protection',
            'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
          ),
          _buildPolicySection(
            'Contact',
            'If you have any questions about this Privacy Policy, please contact us through the app support section.',
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Text(content, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = UserModel.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profile',
        actions: [
          IconButton(onPressed: _editProfile, icon: Icon(Icons.edit_outlined)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
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
              child: Column(
                children: [
                  // Profile avatar
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Icon(Icons.person, size: 50.w, color: Colors.white),
                  ),

                  SizedBox(height: 16.h),

                  // User name
                  Text(
                    user?.name ?? 'User Name',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  // User email
                  Text(
                    user?.email ?? 'user@example.com',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Products', '$_createdProductsCount'),
                      Container(
                        height: 40.h,
                        width: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildStatItem('Trades', '$_completedTradesCount'),
                      Container(
                        height: 40.h,
                        width: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildStatItem(
                        'Reviews',
                        '$_reviewsCount',
                        onTap: () {
                          if (user != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ReviewsScreen(userId: user.id),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Settings sections
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  // Account section
                  _buildSectionTitle('Account'),
                  SizedBox(height: 12.h),

                  // Admin Panel (only for admins)
                  if (user?.isAdmin == true)
                    _buildSettingItem(
                      icon: Icons.admin_panel_settings,
                      title: 'Admin Panel',
                      subtitle: 'Manage users and moderate content',
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(RoutesManager.adminDashboard);
                      },
                    ),

                  _buildSettingItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: _editProfile,
                  ),

                  _buildSettingItem(
                    icon: Icons.favorite_outline,
                    title: 'Favorites',
                    subtitle: 'View your favorite products',
                    onTap: () {
                      Navigator.of(context).pushNamed(RoutesManager.favourites);
                    },
                  ),

                  _buildSettingItem(
                    icon: Icons.history,
                    title: 'Trade History',
                    subtitle: 'View your trading history',
                    onTap: () {
                      Navigator.of(
                        context,
                      ).pushNamed(RoutesManager.tradeHistory);
                    },
                  ),

                  SizedBox(height: 24.h),

                  // Preferences section
                  _buildSectionTitle('Preferences'),
                  SizedBox(height: 12.h),

                  _buildSettingItem(
                    icon: themeProvider.isDark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    title: 'Theme',
                    subtitle: themeProvider.isDark ? 'Dark mode' : 'Light mode',
                    trailing: Switch(
                      value: themeProvider.isDark,
                      onChanged: (value) {
                        themeProvider.changeAppTheme(
                          value ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                  ),

                  _buildSettingItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage notification settings',
                    onTap: () {
                      // Navigate to notifications settings
                    },
                  ),

                  _buildSettingItem(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'English (US)',
                    onTap: () {
                      // Navigate to language settings
                    },
                  ),

                  SizedBox(height: 24.h),

                  // Support section
                  _buildSectionTitle('Support'),
                  SizedBox(height: 12.h),

                  _buildSettingItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help and contact support',
                    onTap: () {
                      // Navigate to help
                    },
                  ),

                  _buildSettingItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    onTap: _showPrivacyPolicy,
                  ),

                  _buildSettingItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'Learn more about the app',
                    onTap: _showAbout,
                  ),

                  SizedBox(height: 24.h),

                  // Debug section
                  _buildSectionTitle('Developer Tools'),
                  SizedBox(height: 12.h),

                  _buildSettingItem(
                    icon: Icons.notifications_active_outlined,
                    title: 'Test Notification',
                    subtitle: 'Send a test push to this device',
                    onTap: _sendTestNotification,
                  ),

                  _buildSettingItem(
                    icon: Icons.copy_outlined,
                    title: 'Copy FCM Token',
                    subtitle: 'Copy device token for console testing',
                    onTap: _copyFcmToken,
                  ),

                  SizedBox(height: 32.h),

                  // Sign out button
                  AuthButton(
                    text: 'Sign Out',
                    onPressed: _signOut,
                    isLoading: _isLoading,
                    backgroundColor: Theme.of(context).colorScheme.error,
                    icon: Icon(Icons.logout, size: 18.w, color: Colors.white),
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 20.w),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        trailing:
            trailing ??
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        tileColor: Theme.of(context).cardColor,
      ),
    );
  }
}
