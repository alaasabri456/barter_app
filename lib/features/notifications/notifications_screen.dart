// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../notifications/viewmodels/notification_viewmodel.dart';
import '../authentication/models/user_model.dart';
import 'models/notification_model.dart';
import '../../core/routes_manager/routes_manager.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = UserModel.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<NotificationModel>>(
        stream: context.read<NotificationViewModel>().getUserNotifications(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64.w,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => Divider(height: 1.h),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationTile(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    NotificationModel notification,
  ) {
    return ListTile(
      tileColor: notification.isRead
          ? null
          : Theme.of(context).primaryColor.withOpacity(0.05),
      leading: CircleAvatar(
        backgroundColor: _getIconColor(notification.type).withOpacity(0.1),
        child: Icon(
          _getIcon(notification.type),
          color: _getIconColor(notification.type),
          size: 20.w,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          fontSize: 14.sp,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4.h),
          Text(
            notification.body,
            style: TextStyle(fontSize: 12.sp),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            _formatTime(notification.createdAt),
            style: TextStyle(fontSize: 10.sp, color: Colors.grey),
          ),
        ],
      ),
      onTap: () async {
        // Mark as read
        if (!notification.isRead) {
          await context.read<NotificationViewModel>().markNotificationAsRead(notification.id);
        }

        // Navigate based on type
        if (notification.type == NotificationType.productUpdate ||
            notification.type == NotificationType.tradeUpdate ||
            notification.type == NotificationType.chatMessage) {
          if (notification.relatedId != null) {
            // Navigate to chat/trade details
            // For now, let's assume we navigate to the chat for that trade
            // We need the tradeId. relatedId is likely the tradeId based on our logic.
            // But ChatScreen needs otherUserId/Name.
            // Ideally we load the trade first.
            // For simplicity, we can navigate to TradeManagementScreen or try to open chat if we can resolve user.

            // Simplest: Go to Trade Management. User can find the trade there.
            // Ideally: Go to specific trade.
            Navigator.pushNamed(context, RoutesManager.tradeManagement);
          }
        }
      },
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.productUpdate:
        return Icons.inventory_2_outlined;
      case NotificationType.tradeUpdate:
        return Icons.swap_horiz_outlined;
      case NotificationType.system:
        return Icons.info_outline;
      case NotificationType.chatMessage:
        return Icons.chat_bubble_outline;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.productUpdate:
        return Colors.amber;
      case NotificationType.tradeUpdate:
        return Colors.blue;
      case NotificationType.system:
        return Colors.green;
      case NotificationType.chatMessage:
        return Colors.purple;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
