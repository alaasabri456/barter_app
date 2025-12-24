enum CategoryStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case CategoryStatus.pending:
        return 'Pending';
      case CategoryStatus.approved:
        return 'Approved';
      case CategoryStatus.rejected:
        return 'Rejected';
    }
  }
}

class CategorySuggestion {
  final String id;
  final String suggestedName;
  final String suggestedBy;
  final String suggestedByName;
  final CategoryStatus status;
  final DateTime createdAt;
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? reviewedAt;

  CategorySuggestion({
    required this.id,
    required this.suggestedName,
    required this.suggestedBy,
    required this.suggestedByName,
    this.status = CategoryStatus.pending,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
  });

  factory CategorySuggestion.fromJson(Map<String, dynamic> json) {
    return CategorySuggestion(
      id: json['id'] ?? '',
      suggestedName: json['suggestedName'] ?? '',
      suggestedBy: json['suggestedBy'] ?? '',
      suggestedByName: json['suggestedByName'] ?? '',
      status: CategoryStatus.values.firstWhere(
        (s) => s.name == (json['status'] ?? 'pending'),
        orElse: () => CategoryStatus.pending,
      ),
      createdAt: _parseDateTime(json['createdAt']),
      reviewedBy: json['reviewedBy'],
      reviewedByName: json['reviewedByName'],
      reviewedAt: json['reviewedAt'] != null
          ? _parseDateTime(json['reviewedAt'])
          : null,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    try {
      return (value as dynamic).toDate();
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'suggestedName': suggestedName,
    'suggestedBy': suggestedBy,
    'suggestedByName': suggestedByName,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'reviewedBy': reviewedBy,
    'reviewedByName': reviewedByName,
    'reviewedAt': reviewedAt?.toIso8601String(),
  };

  CategorySuggestion copyWith({
    String? id,
    String? suggestedName,
    String? suggestedBy,
    String? suggestedByName,
    CategoryStatus? status,
    DateTime? createdAt,
    String? reviewedBy,
    String? reviewedByName,
    DateTime? reviewedAt,
  }) {
    return CategorySuggestion(
      id: id ?? this.id,
      suggestedName: suggestedName ?? this.suggestedName,
      suggestedBy: suggestedBy ?? this.suggestedBy,
      suggestedByName: suggestedByName ?? this.suggestedByName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}

class ApprovedCategory {
  final String id;
  final String name;
  final String addedBy;
  final String addedByName;
  final DateTime addedAt;
  final int productCount;

  ApprovedCategory({
    required this.id,
    required this.name,
    required this.addedBy,
    required this.addedByName,
    required this.addedAt,
    this.productCount = 0,
  });

  factory ApprovedCategory.fromJson(Map<String, dynamic> json) {
    return ApprovedCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      addedBy: json['addedBy'] ?? '',
      addedByName: json['addedByName'] ?? '',
      addedAt: CategorySuggestion._parseDateTime(json['addedAt']),
      productCount: json['productCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'addedBy': addedBy,
    'addedByName': addedByName,
    'addedAt': addedAt.toIso8601String(),
    'productCount': productCount,
  };
}
