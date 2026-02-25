// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import '../config/payment_config.dart';

/// Handles Stripe payment operations.
///
/// NOTE FOR PRODUCTION: The secret key should be moved to a server-side
/// endpoint (e.g., Firebase Cloud Function) and never shipped in the app.
/// For testing purposes, we call the Stripe API directly.
class PaymentService {
  /// Initialize Stripe — call this once in main.dart
  static void initialize() {
    Stripe.publishableKey = PaymentConfig.publishableKey;
    Stripe.merchantIdentifier = 'merchant.com.example.barter';
  }

  /// Creates a PaymentIntent on the Stripe API and presents the Payment Sheet.
  /// Returns the PaymentIntent ID on success, or throws an exception.
  static Future<String> presentPaymentSheet({
    required double amount,
    required String currency,
    required String productTitle,
    required BuildContext context,
  }) async {
    // Capture theme before async gaps
    final themeMode = Theme.of(context).brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;

    // 1. Create PaymentIntent via Stripe REST API
    final clientSecret = await _createPaymentIntent(
      amount: amount,
      currency: currency,
      description: 'Purchase: $productTitle',
    );

    // 2. Initialize the Payment Sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Barter App',
        style: themeMode,
      ),
    );

    // 3. Present the Payment Sheet
    await Stripe.instance.presentPaymentSheet();

    // 4. Extract the PaymentIntent ID from the client_secret
    final paymentIntentId = clientSecret.split('_secret_').first;
    return paymentIntentId;
  }

  /// Creates a Stripe PaymentIntent and returns the client_secret.
  static Future<String> _createPaymentIntent({
    required double amount,
    required String currency,
    String? description,
  }) async {
    try {
      final amountInCents = (amount * 100).round();

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${PaymentConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amountInCents.toString(),
          'currency': currency,
          if (description != null) 'description': description,
          'automatic_payment_methods[enabled]': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final clientSecret = data['client_secret'] as String?;
        if (clientSecret == null) {
          throw Exception('No client_secret returned from Stripe.');
        }
        return clientSecret;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          'Stripe API error: ${error['error']['message'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error creating PaymentIntent: $e');
      rethrow;
    }
  }
}
