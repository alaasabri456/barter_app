import 'package:flutter/foundation.dart';

import '../../../data/repositories/payment_repository.dart';
import '../models/payment_model.dart';

/// ViewModel for payment-related UI state.
class PaymentViewModel extends ChangeNotifier {
  final PaymentRepository _paymentRepository;

  PaymentViewModel({required PaymentRepository paymentRepository})
      : _paymentRepository = paymentRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Phase 1: Create a pending Payment record before launching the gateway.
  // Returns the Firestore document ID for use in Phase 3.
  // ---------------------------------------------------------------------------
  Future<String> createPendingPayment(PaymentModel payment) async {
    _setLoading(true);
    try {
      return await _paymentRepository.createPendingPayment(payment);
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 3: Flip the existing pending record to completed after gateway success.
  // ---------------------------------------------------------------------------
  Future<void> updatePaymentToCompleted({
    required String docId,
    required String transactionId,
  }) async {
    _setLoading(true);
    try {
      await _paymentRepository.updatePaymentToCompleted(
        docId: docId,
        transactionId: transactionId,
      );
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Optional: mark a pending doc as cancelled or failed (fire-and-forget).
  // ---------------------------------------------------------------------------
  Future<void> updatePaymentStatus({
    required String docId,
    required PaymentStatus status,
  }) async {
    await _paymentRepository.updatePaymentStatus(docId: docId, status: status);
  }

  // ---------------------------------------------------------------------------
  // Legacy: kept for backwards compatibility.
  // ---------------------------------------------------------------------------
  Future<void> savePayment(PaymentModel payment) async {
    _setLoading(true);
    try {
      await _paymentRepository.savePayment(payment);
    } finally {
      _setLoading(false);
    }
  }
}
