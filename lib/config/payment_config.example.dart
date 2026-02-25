// ⚠️ This file is gitignored — NEVER commit real keys.
// Copy this file to payment_config.dart and fill in your keys.
//
// For production: move _secretKey to a backend endpoint and
// only keep the publishable key here.

class PaymentConfig {
  static const String publishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY_HERE';
  static const String secretKey = 'sk_test_YOUR_SECRET_KEY_HERE'; // TEST ONLY
}
