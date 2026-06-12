import 'package:flutter/foundation.dart';

import '../../../data/repositories/review_repository.dart';
import '../models/review_model.dart';

/// ViewModel for review-related UI state.
class ReviewViewModel extends ChangeNotifier {
  final ReviewRepository _reviewRepository;

  ReviewViewModel({required ReviewRepository reviewRepository})
      : _reviewRepository = reviewRepository;

  bool _isLoading = false;
  List<ReviewModel> _reviews = [];

  bool get isLoading => _isLoading;
  List<ReviewModel> get reviews => _reviews;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> addReview(ReviewModel review) async {
    _setLoading(true);
    try {
      await _reviewRepository.addReview(review);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserReviews(String userId) async {
    _setLoading(true);
    try {
      _reviews = await _reviewRepository.getUserReviews(userId);
    } finally {
      _setLoading(false);
    }
  }

  Future<List<ReviewModel>> getUserReviews(String userId) async {
    return await _reviewRepository.getUserReviews(userId);
  }
}
