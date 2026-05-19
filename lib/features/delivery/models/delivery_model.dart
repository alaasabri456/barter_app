import 'package:cloud_firestore/cloud_firestore.dart';

enum DeliveryStatus {
  pending,
  picked_up,
  in_transit,
  out_for_delivery,
  delivered
}

extension DeliveryStatusExt on DeliveryStatus {
  String get displayName {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.picked_up:
        return 'Picked Up';
      case DeliveryStatus.in_transit:
        return 'In Transit';
      case DeliveryStatus.out_for_delivery:
        return 'Out for Delivery';
      case DeliveryStatus.delivered:
        return 'Delivered';
    }
  }
}

class DeliveryModel {
  final String id;
  final String userId;
  final String? agentId;
  final String itemName;
  final String fullName;
  final String phoneNumber;
  final String address;
  final DeliveryStatus status;
  final String? tradeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryModel({
    required this.id,
    required this.userId,
    this.agentId,
    required this.itemName,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    this.status = DeliveryStatus.pending,
    this.tradeId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DeliveryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      agentId: data['agentId'],
      itemName: data['itemName'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      status: _parseStatus(data['status']),
      tradeId: data['tradeId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      if (agentId != null) 'agentId': agentId,
      'itemName': itemName,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'status': status.name,
      if (tradeId != null) 'tradeId': tradeId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DeliveryStatus _parseStatus(String? statusStr) {
    if (statusStr == null) return DeliveryStatus.pending;
    return DeliveryStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => DeliveryStatus.pending,
    );
  }
}
