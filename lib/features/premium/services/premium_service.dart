// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/premium_subscription.dart';
import '../../authentication/models/user_model.dart';

/// Encapsulates all premium-related business logic and Firestore operations.
///
/// Follows the **Single Responsibility Principle** — this service owns:
/// - Premium subscription CRUD
/// - Premium status validation
/// - Premium business rules (product limits, fee rates)
class PremiumService {
  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  /// Monthly premium price in EGP.
  static const double premiumPrice = 99.99;

  /// Duration of a single premium subscription period.
  static const int subscriptionDays = 30;

  /// Product listing limit for regular users.
  static const int regularProductLimit = 5;

  /// Service fee percentage for regular users (5%).
  static const double regularServiceFee = 0.05;

  /// Service fee percentage for premium users (2%).
  static const double premiumServiceFee = 0.02;

  // ---------------------------------------------------------------------------
  // Firestore Collection
  // ---------------------------------------------------------------------------

  static CollectionReference<PremiumSubscription>
      _getSubscriptionsCollection() {
    return FirebaseFirestore.instance
        .collection('PremiumSubscriptions')
        .withConverter<PremiumSubscription>(
          fromFirestore: (snapshot, _) =>
              PremiumSubscription.fromJson(snapshot.data()!),
          toFirestore: (sub, _) => sub.toJson(),
        );
  }

  // ---------------------------------------------------------------------------
  // Core Operations
  // ---------------------------------------------------------------------------

  /// Checks whether the user with [userId] has an active premium subscription.
  static Future<bool> isUserPremium(String userId) async {
    try {
      final subscription = await getSubscription(userId);
      return subscription?.isActive ?? false;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  /// Returns the latest premium subscription for [userId], or `null` if none exists.
  static Future<PremiumSubscription?> getSubscription(String userId) async {
    try {
      final collection = _getSubscriptionsCollection();
      final doc = await collection.doc(userId).get();
      return doc.data();
    } catch (e) {
      print('Error getting premium subscription: $e');
      return null;
    }
  }

  /// Activates a premium subscription for [userId] after a successful payment.
  ///
  /// If the user already has an active subscription, the new period is appended
  /// to the existing expiry date (stacking).
  static Future<void> activatePremium({
    required String userId,
    required String transactionId,
    required double amountPaid,
  }) async {
    try {
      final collection = _getSubscriptionsCollection();
      final now = DateTime.now();

      // Check for existing active subscription (stack time)
      final existing = await getSubscription(userId);
      final DateTime startDate;
      final DateTime expiryDate;

      if (existing != null && existing.isActive) {
        // Extend from current expiry
        startDate = existing.startedAt;
        expiryDate =
            existing.expiresAt.add(const Duration(days: subscriptionDays));
      } else {
        startDate = now;
        expiryDate = now.add(const Duration(days: subscriptionDays));
      }

      final subscription = PremiumSubscription(
        userId: userId,
        plan: PremiumPlan.monthly,
        startedAt: startDate,
        expiresAt: expiryDate,
        transactionId: transactionId,
        amountPaid: amountPaid,
      );

      await collection.doc(userId).set(subscription);

      // Update UserModel fields
      await _updateUserPremiumStatus(userId, expiryDate);
    } catch (e) {
      print('Error activating premium: $e');
      throw Exception('Failed to activate premium: $e');
    }
  }

  /// Real-time stream that emits `true` when the user is premium, `false` otherwise.
  static Stream<bool> premiumStatusStream(String userId) {
    return _getSubscriptionsCollection()
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      final subscription = snapshot.data();
      return subscription?.isActive ?? false;
    });
  }

  // ---------------------------------------------------------------------------
  // Business Rules
  // ---------------------------------------------------------------------------

  /// Returns the product listing limit for the user.
  /// Returns `null` for premium users (unlimited).
  static int? getProductLimit(bool isPremium) {
    return isPremium ? null : regularProductLimit;
  }

  /// Returns the service fee percentage based on premium status.
  static double getServiceFeePercent(bool isPremium) {
    return isPremium ? premiumServiceFee : regularServiceFee;
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  /// Updates the cached premium fields on the user document in Firestore.
  static Future<void> _updateUserPremiumStatus(
    String userId,
    DateTime expiresAt,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'isPremiumActive': true,
        'premiumExpiresAt': Timestamp.fromDate(expiresAt),
      });

      // Update in-memory cache
      if (UserModel.currentUser?.id == userId) {
        UserModel.currentUser!.isPremiumActive = true;
        UserModel.currentUser!.premiumExpiresAt = expiresAt;
      }
    } catch (e) {
      print('Error updating user premium status: $e');
    }
  }
}
