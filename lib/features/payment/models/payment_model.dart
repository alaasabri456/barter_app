import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { pending, completed, failed, cancelled, refunded }

class PaymentModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String productId;
  final String productTitle;

  /// The total amount charged to the buyer (productPrice + serviceFee).
  final double amount;

  /// The net amount to be credited to the seller (product price only, no platform fee).
  final double productPrice;

  /// The platform service fee retained by the system (amount - productPrice).
  final double serviceFee;

  final String currency;
  final String transactionId;
  final PaymentStatus status;
  final DateTime createdAt;

  /// Set when the payment transitions from pending → completed.
  final DateTime? completedAt;

  /// Paymob order ID stored at pending-creation time for reconciliation.
  final String? paymobOrderId;

  PaymentModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.productId,
    required this.productTitle,
    required this.amount,
    required this.productPrice,
    required this.serviceFee,
    required this.currency,
    required this.transactionId,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.paymobOrderId,
  });

  PaymentModel copyWith({
    String? id,
    String? buyerId,
    String? buyerName,
    String? sellerId,
    String? productId,
    String? productTitle,
    double? amount,
    double? productPrice,
    double? serviceFee,
    String? currency,
    String? transactionId,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? paymobOrderId,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      amount: amount ?? this.amount,
      productPrice: productPrice ?? this.productPrice,
      serviceFee: serviceFee ?? this.serviceFee,
      currency: currency ?? this.currency,
      transactionId: transactionId ?? this.transactionId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      paymobOrderId: paymobOrderId ?? this.paymobOrderId,
    );
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;
    return PaymentModel(
      id: json['id'] ?? '',
      buyerId: json['buyerId'] ?? '',
      buyerName: json['buyerName'] ?? '',
      sellerId: json['sellerId'] ?? '',
      productId: json['productId'] ?? '',
      productTitle: json['productTitle'] ?? '',
      amount: amount,
      // Fallback: if productPrice is missing in older documents, use amount (no split).
      productPrice: (json['productPrice'] as num?)?.toDouble() ?? amount,
      serviceFee: (json['serviceFee'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'EGP',
      transactionId: json['transactionId'] ?? '',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      paymobOrderId: json['paymobOrderId'] as String?,
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
      // Total charged to buyer
      'amount': amount,
      // Net amount to credit to seller (product price only, no platform fee)
      'productPrice': productPrice,
      // Platform service fee retained by the system
      'serviceFee': serviceFee,
      'currency': currency,
      'transactionId': transactionId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (paymobOrderId != null) 'paymobOrderId': paymobOrderId,
    };
  }
}
