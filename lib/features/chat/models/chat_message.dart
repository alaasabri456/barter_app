import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String tradeId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.tradeId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  ChatMessage.fromJson(Map<String, dynamic> json)
    : this(
        id: json['id'] ?? '',
        tradeId: json['tradeId'] ?? '',
        senderId: json['senderId'] ?? '',
        text: json['text'] ?? '',
        timestamp: _parseDateTime(json['timestamp']),
        isRead: json['isRead'] ?? false,
      );

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    } else if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tradeId': tradeId,
    'senderId': senderId,
    'text': text,
    'timestamp': Timestamp.fromDate(timestamp),
    'isRead': isRead,
  };

  ChatMessage copyWith({
    String? id,
    String? tradeId,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      tradeId: tradeId ?? this.tradeId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
