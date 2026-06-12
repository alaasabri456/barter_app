// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/payment/models/payment_model.dart';

/// Repository responsible for payment-related data operations.
class PaymentRepository {
  final FirebaseFirestore _firestore;

  PaymentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Phase 1 — Create a pending record BEFORE launching the payment gateway.
  // Returns the Firestore document ID so the caller can update it in Phase 3.
  // ---------------------------------------------------------------------------
  Future<String> createPendingPayment(PaymentModel payment) async {
    try {
      final ref = _firestore.collection('Payments').doc();
      final withId = payment.copyWith(
        id: ref.id,
        status: PaymentStatus.pending,
      );
      await ref.set(withId.toJson());
      return ref.id;
    } catch (e) {
      throw Exception('Failed to create pending payment: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 3 — Update the existing pending record to completed after the
  // payment gateway confirms success.
  // ---------------------------------------------------------------------------
  Future<void> updatePaymentToCompleted({
    required String docId,
    required String transactionId,
  }) async {
    try {
      await _firestore.collection('Payments').doc(docId).update({
        'status': PaymentStatus.completed.name,
        'transactionId': transactionId,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update payment to completed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Optional: mark a pending record as cancelled/failed so it doesn't sit as
  // an orphan. Called when the user dismisses the payment WebView.
  // ---------------------------------------------------------------------------
  Future<void> updatePaymentStatus({
    required String docId,
    required PaymentStatus status,
  }) async {
    try {
      await _firestore.collection('Payments').doc(docId).update({
        'status': status.name,
      });
    } catch (e) {
      // Non-critical — log and swallow so the UI isn't blocked.
      print('Failed to update payment status to ${status.name}: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Legacy: kept for backwards compatibility; not used in the new flow.
  // ---------------------------------------------------------------------------
  Future<void> savePayment(PaymentModel payment) async {
    try {
      final ref = _firestore.collection('Payments').doc();
      final withId = payment.copyWith(id: ref.id);
      await ref.set(withId.toJson());
    } catch (e) {
      throw Exception('Failed to save payment: $e');
    }
  }
}
