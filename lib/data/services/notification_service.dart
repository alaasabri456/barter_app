// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../features/authentication/models/user_model.dart';
import '../../services/fcm_v1_service.dart';

/// Localized notification string templates for push notifications.
///
/// NOTE: In-app Notification documents are now created exclusively by Cloud
/// Functions triggered on real platform events (trade, chat, review, report,
/// product update). These string templates are used only for the FCM push
/// payload sent client-side.
const Map<String, Map<String, String>> localizedNotificationStrings = {
  'en': {
    'newOfferTitle': 'New Trade Offer',
    'newOfferBody': '{sender} sent you a trade offer.',
    'counterOfferTitle': 'New Counter Offer',
    'counterOfferBody': '{sender} sent a counter offer.',
    'tradeAcceptedTitle': 'Trade Accepted!',
    'tradeAcceptedBody': 'Your trade offer has been accepted!',
    'tradeRejectedTitle': 'Trade Rejected',
    'tradeRejectedBody': 'Your trade offer was rejected.',
    'tradeAutoRejectedBody':
        'Your offer was cancelled because the item is no longer available.',
    'tradeCompletedTitle': 'Trade Completed!',
    'tradeCompletedBody': 'The trade has been confirmed as completed.',
    'newMessageTitle': 'New Message',
    'newMessageBody': '{sender}: {message}',
    'newReviewTitle': 'New Review received',
    'newReviewBody': '{sender} left you a review: {rating}⭐',
    'newReportTitle': 'New Report Submitted',
    'newReportBody':
        'A new report was submitted for "{product}" by {reporter}.',
  },
  'ar': {
    'newOfferTitle': 'عرض مبادلة جديد',
    'newOfferBody': 'أرسل لك {sender} عرض مبادلة.',
    'counterOfferTitle': 'عرض مقابل جديد',
    'counterOfferBody': 'أرسل {sender} عرضاً مقابلاً.',
    'tradeAcceptedTitle': 'تم قبول المبادلة!',
    'tradeAcceptedBody': 'تم قبول عرض المبادلة الخاص بك!',
    'tradeRejectedTitle': 'تم رفض المبادلة',
    'tradeRejectedBody': 'تم رفض عرض المبادلة الخاص بك.',
    'tradeAutoRejectedBody': 'تم إلغاء عرضك لأن السلعة لم تعد متوفرة.',
    'tradeCompletedTitle': 'اكتملت المبادلة!',
    'tradeCompletedBody': 'تم تأكيد اكتمال المبادلة.',
    'newMessageTitle': 'رسالة جديدة',
    'newMessageBody': '{sender}: {message}',
    'newReviewTitle': 'تم استلام تقييم جديد',
    'newReviewBody': 'ترك لك {sender} تقييمًا: {rating}⭐',
    'newReportTitle': 'تم تقديم بلاغ جديد',
    'newReportBody': 'تم تقديم بلاغ جديد عن "{product}" بواسطة {reporter}.',
  },
};

/// Shared service for sending push notifications.
///
/// In-app Notification documents (Firestore `Notifications/` collection) are
/// no longer written by the client. They are created exclusively by Cloud
/// Functions as a verified server-side side-effect of real platform events.
/// This service only handles the FCM push notification delivery.
class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ─── Firestore helpers ────────────────────────────────────────────────

  CollectionReference<UserModel> _getUsersCollection() {
    return _firestore.collection("Users").withConverter<UserModel>(
          fromFirestore: (snapshot, _) => UserModel.fromJson(snapshot.data()!),
          toFirestore: (user, _) => user.toJson(),
        );
  }

  // ─── Public API ───────────────────────────────────────────────────────

  /// Get a user's FCM token from Firestore.
  Future<String?> getUserFcmToken(String userId) async {
    try {
      final snapshot = await _getUsersCollection().doc(userId).get();
      return snapshot.data()?.fcmToken;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Send a push notification via FCM v1 HTTP API.
  Future<void> sendPushNotification({
    required String recipientToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final accessToken = await FcmV1Service.getAccessToken();
      const projectId = 'barter-30a05';
      const url =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': recipientToken,
            'notification': {'title': title, 'body': body},
            'data':
                data?.map((key, value) => MapEntry(key, value.toString())) ??
                    {},
          },
        }),
      );

      if (response.statusCode == 200) {
        print('FCM v1 notification sent successfully');
      } else {
        print('FCM v1 notification failed: ${response.body}');
      }
    } catch (e) {
      print('Error sending FCM v1 notification: $e');
    }
  }

  /// Send a localized push notification to a user.
  ///
  /// Resolves the recipient's preferred language, builds the localized title
  /// and body, and fires an FCM push notification.
  ///
  /// The corresponding in-app Notification document is created by the Cloud
  /// Function that triggered this call chain (e.g. `onTradeCreated`) — no
  /// Firestore write happens here.
  Future<void> sendLocalizedNotification({
    required String recipientId,
    required String titleKey,
    required String bodyKey,
    // ignore: avoid_unused_parameters — kept for call-site compat; not written to Firestore
    dynamic type,
    Map<String, String>? bodyArgs,
    Map<String, dynamic>? data,
  }) async {
    try {
      final recipientSnapshot =
          await _getUsersCollection().doc(recipientId).get();
      final recipient = recipientSnapshot.data();
      if (recipient == null) return;

      final lang = recipient.languageCode;
      String title = localizedNotificationStrings[lang]?[titleKey] ??
          localizedNotificationStrings['en']![titleKey]!;
      String body = localizedNotificationStrings[lang]?[bodyKey] ??
          localizedNotificationStrings['en']![bodyKey]!;

      // Replace placeholders
      if (bodyArgs != null) {
        bodyArgs.forEach((key, value) {
          body = body.replaceAll('{$key}', value);
        });
      }

      // Send Push Notification only — in-app notification is written by CF.
      if (recipient.fcmToken != null) {
        await sendPushNotification(
          recipientToken: recipient.fcmToken!,
          title: title,
          body: body,
          data: data,
        );
      }
    } catch (e) {
      print('Failed to send localized notification: $e');
    }
  }
}
