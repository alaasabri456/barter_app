// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/notifications/models/notification_model.dart';
import '../../features/reviews/models/review_model.dart';
import '../services/notification_service.dart';

/// Repository responsible for review-related data operations.
class ReviewRepository {
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  ReviewRepository({
    FirebaseFirestore? firestore,
    required NotificationService notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService;

  Future<void> addReview(ReviewModel review) async {
    try {
      final reviewsCollection = _firestore.collection('reviews');
      await reviewsCollection.doc(review.id).set(review.toJson());

      // Notify the user about the new review
      await _notificationService.sendLocalizedNotification(
        recipientId: review.targetUserId,
        titleKey: 'newReviewTitle',
        bodyKey: 'newReviewBody',
        type: NotificationType.system,
        bodyArgs: {
          'sender': review.reviewerName,
          'rating': review.rating.toString(),
        },
        data: {
          'type': 'new_review',
          'reviewId': review.id,
        },
      );
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final reviewsCollection = _firestore.collection('reviews');
      final snapshot = await reviewsCollection
          .where('targetUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user reviews: $e');
    }
  }
}
