import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { pending, completed, failed, refunded }

class PaymentModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String productId;
  final String productTitle;
  final double amount;
  final String currency;
  final String transactionId;
  final PaymentStatus status;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.productId,
    required this.productTitle,
    required this.amount,
    required this.currency,
    required this.transactionId,
    required this.status,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      buyerId: json['buyerId'] ?? '',
      buyerName: json['buyerName'] ?? '',
      sellerId: json['sellerId'] ?? '',
      productId: json['productId'] ?? '',
      productTitle: json['productTitle'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'EGP',
      transactionId: json['transactionId'] ?? '',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'productId': productId,
      'productTitle': productTitle,
      'amount': amount,
      'currency': currency,
      'transactionId': transactionId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
