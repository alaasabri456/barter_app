import 'package:cloud_firestore/cloud_firestore.dart';

enum WithdrawalStatus { pending, approved, completed, rejected }

class WithdrawalRequestModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final double amount;
  final Map<String, dynamic> bankDetails;
  final WithdrawalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  WithdrawalRequestModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.amount,
    required this.bankDetails,
    this.status = WithdrawalStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WithdrawalRequestModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequestModel(
      id: json['id'] ?? '',
      sellerId: json['sellerId'] ?? '',
      sellerName: json['sellerName'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      bankDetails: json['bankDetails'] as Map<String, dynamic>? ?? {},
      status: _parseStatus(json['status']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'amount': amount,
      'bankDetails': bankDetails,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static WithdrawalStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':
        return WithdrawalStatus.approved;
      case 'completed':
        return WithdrawalStatus.completed;
      case 'rejected':
        return WithdrawalStatus.rejected;
      case 'pending':
      default:
        return WithdrawalStatus.pending;
    }
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }
}
