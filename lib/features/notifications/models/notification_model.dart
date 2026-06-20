import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { productUpdate, tradeUpdate, system, chatMessage }

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedId; // productId or tradeId
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      relatedId: json['relatedId'],
      isRead: json['isRead'] ?? false,
      // Cloud Functions write createdAt as a Firestore server Timestamp;
      // older client-written docs stored it as an ISO 8601 String.
      // Handle both types gracefully.
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  /// Parses a createdAt value that may be:
  ///   - a Firestore [Timestamp] (written by Cloud Functions via serverTimestamp)
  ///   - an ISO 8601 [String] (written by the old client-side code)
  ///   - null (fallback to now)
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    // Fallback for any unexpected type
    return DateTime.now();
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
