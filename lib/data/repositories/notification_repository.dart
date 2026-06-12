// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/notifications/models/notification_model.dart';

/// Repository responsible for in-app notification data operations.
class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _getNotificationsCollection() {
    return _firestore.collection('Notifications');
  }

  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _getNotificationsCollection()
          .doc(notification.id)
          .set(notification.toJson());
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _getNotificationsCollection()
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => NotificationModel.fromJson(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    });
  }

  Stream<int> getUnreadNotificationCount(String userId) {
    return _getNotificationsCollection()
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _getNotificationsCollection().doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }
}
