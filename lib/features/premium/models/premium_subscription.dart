import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the available premium plan types.
enum PremiumPlan {
  monthly;

  String get displayName {
    switch (this) {
      case PremiumPlan.monthly:
        return 'Monthly';
    }
  }
}

/// Immutable data model representing a user's premium subscription.
///
/// Stored in the `PremiumSubscriptions` Firestore collection, keyed by [userId].
/// The subscription is considered active when [DateTime.now] is before [expiresAt].
class PremiumSubscription {
  final String userId;
  final PremiumPlan plan;
  final DateTime startedAt;
  final DateTime expiresAt;
  final String transactionId;
  final double amountPaid;
  final String currency;

  const PremiumSubscription({
    required this.userId,
    required this.plan,
    required this.startedAt,
    required this.expiresAt,
    required this.transactionId,
    required this.amountPaid,
    this.currency = 'EGP',
  });

  /// Whether this subscription is currently active.
  bool get isActive => DateTime.now().isBefore(expiresAt);

  /// Days remaining until expiration. Returns 0 if expired.
  int get daysRemaining {
    final remaining = expiresAt.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  factory PremiumSubscription.fromJson(Map<String, dynamic> json) {
    return PremiumSubscription(
      userId: json['userId'] ?? '',
      plan: PremiumPlan.values.firstWhere(
        (p) => p.name == (json['plan'] ?? 'monthly'),
        orElse: () => PremiumPlan.monthly,
      ),
      startedAt: _parseDateTime(json['startedAt']),
      expiresAt: _parseDateTime(json['expiresAt']),
      transactionId: json['transactionId'] ?? '',
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'EGP',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'plan': plan.name,
        'startedAt': Timestamp.fromDate(startedAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'transactionId': transactionId,
        'amountPaid': amountPaid,
        'currency': currency,
      };

  PremiumSubscription copyWith({
    String? userId,
    PremiumPlan? plan,
    DateTime? startedAt,
    DateTime? expiresAt,
    String? transactionId,
    double? amountPaid,
    String? currency,
  }) {
    return PremiumSubscription(
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      transactionId: transactionId ?? this.transactionId,
      amountPaid: amountPaid ?? this.amountPaid,
      currency: currency ?? this.currency,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }

  @override
  String toString() =>
      'PremiumSubscription(userId: $userId, plan: $plan, active: $isActive, '
      'expiresAt: $expiresAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PremiumSubscription &&
          other.userId == userId &&
          other.transactionId == transactionId;

  @override
  int get hashCode => userId.hashCode ^ transactionId.hashCode;
}
