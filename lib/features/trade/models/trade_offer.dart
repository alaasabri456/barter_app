// models/trade_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TradeStatus { pending, accepted, rejected, expired, completed, cancelled }

enum TradeType {
  itemForItem,
  serviceForItem,
  serviceForService,
  multiForSingle,
  any,
}

class TradeOffer {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final List<String> offeredProductIds; // Items/services being offered
  final List<String> requestedProductIds; // Items/services being requested
  final String? message;
  final TradeStatus status;
  final TradeType type;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? updatedAt;
  final List<TradeCounterOffer> counterOffers;
  final bool isCounterOffer;

  // Chat related fields
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final bool hasUnreadMessages;

  TradeOffer({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.offeredProductIds,
    required this.requestedProductIds,
    this.message,
    required this.status,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
    this.updatedAt,
    this.counterOffers = const [],
    this.isCounterOffer = false,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.hasUnreadMessages = false,
  });

  factory TradeOffer.fromJson(Map<String, dynamic> json) {
    return TradeOffer(
      id: json['id'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      fromUserName: json['fromUserName'] ?? '',
      toUserId: json['toUserId'] ?? '',
      toUserName: json['toUserName'] ?? '',
      offeredProductIds: List<String>.from(json['offeredProductIds'] ?? []),
      requestedProductIds: List<String>.from(json['requestedProductIds'] ?? []),
      message: json['message'],
      status: TradeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TradeStatus.pending,
      ),
      type: TradeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TradeType.itemForItem,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      expiresAt: (json['expiresAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      counterOffers: (json['counterOffers'] as List<dynamic>?)
              ?.map((e) => TradeCounterOffer.fromJson(e))
              .toList() ??
          [],
      isCounterOffer: json['isCounterOffer'] ?? false,
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null
          ? (json['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: json['lastMessageSenderId'],
      hasUnreadMessages: json['hasUnreadMessages'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'offeredProductIds': offeredProductIds,
      'requestedProductIds': requestedProductIds,
      'message': message,
      'status': status.name,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'counterOffers': counterOffers.map((e) => e.toJson()).toList(),
      'isCounterOffer': isCounterOffer,
      'lastMessage': lastMessage,
      'lastMessageTime':
          lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'lastMessageSenderId': lastMessageSenderId,
      'hasUnreadMessages': hasUnreadMessages,
    };
  }

  TradeOffer copyWith({
    String? id,
    String? fromUserId,
    String? fromUserName,
    String? toUserId,
    String? toUserName,
    List<String>? offeredProductIds,
    List<String>? requestedProductIds,
    String? message,
    TradeStatus? status,
    TradeType? type,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? updatedAt,
    List<TradeCounterOffer>? counterOffers,
    bool? isCounterOffer,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    bool? hasUnreadMessages,
  }) {
    return TradeOffer(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserId: toUserId ?? this.toUserId,
      toUserName: toUserName ?? this.toUserName,
      offeredProductIds: offeredProductIds ?? this.offeredProductIds,
      requestedProductIds: requestedProductIds ?? this.requestedProductIds,
      message: message ?? this.message,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      updatedAt: updatedAt ?? this.updatedAt,
      counterOffers: counterOffers ?? this.counterOffers,
      isCounterOffer: isCounterOffer ?? this.isCounterOffer,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
    );
  }
}

class TradeCounterOffer {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final List<String> offeredProductIds;
  final List<String> requestedProductIds;
  final String? message;
  final DateTime createdAt;
  final bool isAccepted;

  TradeCounterOffer({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.offeredProductIds,
    required this.requestedProductIds,
    this.message,
    required this.createdAt,
    this.isAccepted = false,
  });

  factory TradeCounterOffer.fromJson(Map<String, dynamic> json) {
    return TradeCounterOffer(
      id: json['id'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      fromUserName: json['fromUserName'] ?? '',
      offeredProductIds: List<String>.from(json['offeredProductIds'] ?? []),
      requestedProductIds: List<String>.from(json['requestedProductIds'] ?? []),
      message: json['message'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isAccepted: json['isAccepted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'offeredProductIds': offeredProductIds,
      'requestedProductIds': requestedProductIds,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAccepted': isAccepted,
    };
  }

  TradeCounterOffer copyWith({
    String? id,
    String? fromUserId,
    String? fromUserName,
    List<String>? offeredProductIds,
    List<String>? requestedProductIds,
    String? message,
    DateTime? createdAt,
    bool? isAccepted,
  }) {
    return TradeCounterOffer(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      offeredProductIds: offeredProductIds ?? this.offeredProductIds,
      requestedProductIds: requestedProductIds ?? this.requestedProductIds,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }
}

class TradeHistory {
  final String id;
  final String tradeId;
  final String action;
  final String performedByUserId;
  final String performedByUserName;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  TradeHistory({
    required this.id,
    required this.tradeId,
    required this.action,
    required this.performedByUserId,
    required this.performedByUserName,
    required this.timestamp,
    this.details,
  });

  factory TradeHistory.fromJson(Map<String, dynamic> json) {
    return TradeHistory(
      id: json['id'] ?? '',
      tradeId: json['tradeId'] ?? '',
      action: json['action'] ?? '',
      performedByUserId: json['performedByUserId'] ?? '',
      performedByUserName: json['performedByUserName'] ?? '',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tradeId': tradeId,
      'action': action,
      'performedByUserId': performedByUserId,
      'performedByUserName': performedByUserName,
      'timestamp': Timestamp.fromDate(timestamp),
      'details': details,
    };
  }
}
