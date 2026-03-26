// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:paymob_payment/paymob_payment.dart';

import '../config/payment_config.dart';

/// Handles Paymob payment operations.
class PaymentService {
  /// Initialize Paymob — call this once in main.dart
  static void initialize() {
    PaymobPayment.instance.initialize(
      apiKey: PaymentConfig.apiKey,
      integrationID: PaymentConfig.integrationId,
      iFrameID: PaymentConfig.iFrameId,
    );
  }

  /// Launches the Paymob WebView checkout.
  /// Returns a [PaymobResponse] on completion (success or failure), or null if dismissed.
  static Future<PaymobResponse?> pay({
    required double amount,
    required BuildContext context,
    void Function(PaymobResponse)? onPayment,
  }) async {
    try {
      // Paymob expects amount in cents (piasters): 100 EGP = 10000
      final amountInCents = (amount * 100).round().toString();

      final response = await PaymobPayment.instance.pay(
        context: context,
        currency: 'EGP',
        amountInCents: amountInCents,
        onPayment: onPayment,
      );

      return response;
    } catch (e) {
      print('Paymob payment error: $e');
      rethrow;
    }
  }
}
