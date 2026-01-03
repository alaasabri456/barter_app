class ProductModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? customCategory; // For pending custom categories
  final String condition;
  final String ownerId;
  final String ownerName;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAvailable;
  final List<String> tags;
  final String? location;
  final ProductStatus status;
  final int viewCount;
  final List<String> interestedUsers;
  final List<String> viewedUserIds;
  final List<String> reportedByUserIds;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.customCategory,
    required this.condition,
    required this.ownerId,
    required this.ownerName,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    this.isAvailable = true,
    this.tags = const [],
    this.location,
    this.status = ProductStatus.available,
    this.viewCount = 0,
    this.interestedUsers = const [],
    this.viewedUserIds = const [],
    this.reportedByUserIds = const [],
  });

  ProductModel.fromJson(Map<String, dynamic> json)
    : this(
        id: json["id"] ?? '',
        title: json["title"] ?? '',
        description: json["description"] ?? '',
        category: json["category"] ?? '',
        customCategory: json["customCategory"],
        condition: json["condition"] ?? '',
        ownerId: json["ownerId"] ?? '',
        ownerName: json["ownerName"] ?? '',
        images:
            (json["images"] as List<dynamic>?)
                ?.map((obj) => obj.toString())
                .toList() ??
            [],
        createdAt: _parseDateTime(json["createdAt"]),
        updatedAt: _parseDateTime(json["updatedAt"]),
        isAvailable: json["isAvailable"] ?? true,
        tags:
            (json["tags"] as List<dynamic>?)
                ?.map((obj) => obj.toString())
                .toList() ??
            [],
        location: json["location"],
        status: ProductStatus.values.firstWhere(
          (status) => status.name == (json["status"] ?? "available"),
          orElse: () => ProductStatus.available,
        ),
        viewCount: json["viewCount"] ?? 0,
        interestedUsers:
            (json["interestedUsers"] as List<dynamic>?)
                ?.map((obj) => obj.toString())
                .toList() ??
            [],
        viewedUserIds:
            (json["viewedUserIds"] as List<dynamic>?)
                ?.map((obj) => obj.toString())
                .toList() ??
            [],
        reportedByUserIds:
            (json["reportedByUserIds"] as List<dynamic>?)
                ?.map((obj) => obj.toString())
                .toList() ??
            [],
      );

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    } else {
      // Handle Firestore Timestamp
      try {
        return (value as dynamic).toDate();
      } catch (e) {
        return DateTime.now();
      }
    }
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "description": description,
    "category": category,
    "customCategory": customCategory,
    "condition": condition,
    "ownerId": ownerId,
    "ownerName": ownerName,
    "images": images,
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt.toIso8601String(),
    "isAvailable": isAvailable,
    "tags": tags,
    "location": location,
    "status": status.name,
    "viewCount": viewCount,
    "interestedUsers": interestedUsers,
    "viewedUserIds": viewedUserIds,
    "reportedByUserIds": reportedByUserIds,
  };

  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? customCategory,
    String? condition,
    String? ownerId,
    String? ownerName,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAvailable,
    List<String>? tags,
    String? location,
    ProductStatus? status,
    int? viewCount,
    List<String>? interestedUsers,
    List<String>? viewedUserIds,
    List<String>? reportedByUserIds,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      condition: condition ?? this.condition,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
      interestedUsers: interestedUsers ?? this.interestedUsers,
      viewedUserIds: viewedUserIds ?? this.viewedUserIds,
      reportedByUserIds: reportedByUserIds ?? this.reportedByUserIds,
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, title: $title, category: $category, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum ProductStatus { available, traded, reserved, unavailable }

enum ProductCondition { new_item, like_new, good, fair, poor }

enum ProductCategory {
  electronics,
  clothing,
  books,
  sports,
  home,
  toys,
  automotive,
  jewelry,
  health,
  others,
}

extension ProductStatusExtension on ProductStatus {
  String get displayName {
    switch (this) {
      case ProductStatus.available:
        return 'Available';
      case ProductStatus.traded:
        return 'Traded';
      case ProductStatus.reserved:
        return 'Reserved';
      case ProductStatus.unavailable:
        return 'Unavailable';
    }
  }
}

extension ProductConditionExtension on ProductCondition {
  String get displayName {
    switch (this) {
      case ProductCondition.new_item:
        return 'New';
      case ProductCondition.like_new:
        return 'Like New';
      case ProductCondition.good:
        return 'Good';
      case ProductCondition.fair:
        return 'Fair';
      case ProductCondition.poor:
        return 'Poor';
    }
  }
}

extension ProductCategoryExtension on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.electronics:
        return 'Electronics';
      case ProductCategory.clothing:
        return 'Clothing';
      case ProductCategory.books:
        return 'Books';
      case ProductCategory.sports:
        return 'Sports & Outdoors';
      case ProductCategory.home:
        return 'Home & Garden';
      case ProductCategory.toys:
        return 'Toys & Games';
      case ProductCategory.automotive:
        return 'Automotive';
      case ProductCategory.jewelry:
        return 'Jewelry';
      case ProductCategory.health:
        return 'Health & Beauty';
      case ProductCategory.others:
        return 'Others';
    }
  }

  static List<String> get allDisplayNames {
    return ProductCategory.values
        .map((category) => category.displayName)
        .toList();
  }

  static ProductCategory fromDisplayName(String displayName) {
    return ProductCategory.values.firstWhere(
      (category) => category.displayName == displayName,
      orElse: () => ProductCategory.others,
    );
  }
}
