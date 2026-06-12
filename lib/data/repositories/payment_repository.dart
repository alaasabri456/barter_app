// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/payment/models/payment_model.dart';

/// Repository responsible for payment-related data operations.
class PaymentRepository {
  final FirebaseFirestore _firestore;

  PaymentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> savePayment(PaymentModel payment) async {
    try {
      final ref = _firestore.collection('Payments').doc();
      final withId = PaymentModel(
        id: ref.id,
        buyerId: payment.buyerId,
        buyerName: payment.buyerName,
        sellerId: payment.sellerId,
        productId: payment.productId,
        productTitle: payment.productTitle,
        amount: payment.amount,
        currency: payment.currency,
        transactionId: payment.transactionId,
        status: payment.status,
        createdAt: payment.createdAt,
      );
      await ref.set(withId.toJson());
    } catch (e) {
      throw Exception('Failed to save payment: $e');
    }
  }
}
