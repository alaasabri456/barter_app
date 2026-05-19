// ignore_for_file: avoid_print
import 'package:barter/config/payment_config.example.dart';
import 'package:flutter/material.dart';
import 'package:paymob_payment/paymob_payment.dart';
import '../features/authentication/models/user_model.dart';


/// Handles Paymob payment operations.
class PaymentService {
  /// Initialize Paymob — call this once in main.dart
  static Future<void> initialize() async {
    await PaymobPayment.instance.initialize(
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
    UserModel? user,
    void Function(PaymobResponse)? onPayment,
  }) async {
    try {
      // Paymob expects amount in cents (piasters): 100 EGP = 10000
      final amountInCents = (amount * 100).round().toString();

      final response = await PaymobPayment.instance.pay(
        context: context,
        currency: 'EGP',
        amountInCents: amountInCents,
        onPayment: (resp) {
          if (onPayment != null) onPayment(resp);
        },
        billingData: PaymobBillingData(
          firstName: user?.name.split(' ').first ?? "Guest",
          lastName: (user?.name.split(' ').length ?? 0) > 1
              ? user!.name.split(' ').last
              : "User",
          email: user?.email ?? "guest@example.com",
          phoneNumber: "0123456789", // Paymob requires phone without + prefix
          apartment: "NA",
          building: "NA",
          city: "NA",
          country: "EG",
          floor: "NA",
          postalCode: "NA",
          shippingMethod: "NA",
          state: "NA",
          street: "NA",
        ),
      );

      return response;
    } catch (e) {
      print('Paymob payment error: $e');
      rethrow;
    }
  }
}
