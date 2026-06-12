// ignore_for_file: avoid_print
import 'package:barter/config/payment_config.example.dart';
import 'package:flutter/material.dart';
import 'package:pay_with_paymob/pay_with_paymob.dart';
import '../features/authentication/models/user_model.dart';

/// Handles Paymob payment operations.
/// Supports both card (Visa/Mastercard) and mobile wallet (Vodafone Cash).
class PaymentService {
  /// Initialize Paymob — call this once in main.dart
  static void initialize() {
    PaymentData.initialize(
      apiKey: PaymentConfig.apiKey,
      iframeId: PaymentConfig.iFrameId.toString(),
      integrationCardId: PaymentConfig.integrationId.toString(),
      integrationMobileWalletId: PaymentConfig.walletIntegrationId.toString(),
    );
  }

  /// Updates user billing data in PaymentData.
  /// Call this when user context is available (e.g., before navigating to checkout).
  static void updateUserData(UserModel? user) {
    if (user == null) return;
    final nameParts = user.name.trim().split(' ');
    PaymentData.initialize(
      apiKey: PaymentConfig.apiKey,
      iframeId: PaymentConfig.iFrameId.toString(),
      integrationCardId: PaymentConfig.integrationId.toString(),
      integrationMobileWalletId: PaymentConfig.walletIntegrationId.toString(),
      userData: UserData(
        name: nameParts.first,
        lastName: nameParts.length > 1 ? nameParts.last : 'User',
        email: user.email,
        phone: '01000000000', // Paymob requires a valid Egyptian phone number
      ),
    );
  }

  /// Navigates to the Paymob payment view (card + mobile wallet selector).
  ///
  /// [amount]      — total amount in EGP (e.g. 99.5 for 99.50 EGP)
  /// [context]     — current BuildContext for navigation
  /// [user]        — logged-in user (used to pre-fill billing data)
  /// [onSuccess]   — called when payment completes successfully
  /// [onError]     — called when payment fails or is cancelled
  static void pay({
    required double amount,
    required BuildContext context,
    UserModel? user,
    required VoidCallback onSuccess,
    required VoidCallback onError,
  }) {
    try {
      // Update billing data with current user info before opening payment view
      updateUserData(user);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentView(
            price: amount,
            onPaymentSuccess: onSuccess,
            onPaymentError: onError,
          ),
        ),
      );
    } catch (e) {
      print('Paymob payment error: $e');
      onError();
    }
  }
}
