class ReviewModel {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String targetUserId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String tradeId;

  ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.targetUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.tradeId,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      reviewerId: json['reviewerId'] ?? '',
      reviewerName: json['reviewerName'] ?? '',
      targetUserId: json['targetUserId'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      tradeId: json['tradeId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'targetUserId': targetUserId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'tradeId': tradeId,
    };
  }
}
