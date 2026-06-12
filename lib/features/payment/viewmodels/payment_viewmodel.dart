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

  Future<void> savePayment(PaymentModel payment) async {
    _setLoading(true);
    try {
      await _paymentRepository.savePayment(payment);
    } finally {
      _setLoading(false);
    }
  }
}
