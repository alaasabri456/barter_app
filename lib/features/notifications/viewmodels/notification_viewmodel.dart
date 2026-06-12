import 'package:flutter/foundation.dart';

import '../../../data/repositories/notification_repository.dart';
import '../models/notification_model.dart';

/// ViewModel for notification-related UI state.
class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _notificationRepository;

  NotificationViewModel({required NotificationRepository notificationRepository})
      : _notificationRepository = notificationRepository;

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _notificationRepository.getUserNotifications(userId);
  }

  Stream<int> getUnreadNotificationCount(String userId) {
    return _notificationRepository.getUnreadNotificationCount(userId);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationRepository.markNotificationAsRead(notificationId);
  }
}
