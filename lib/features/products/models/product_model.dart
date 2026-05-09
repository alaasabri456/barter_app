// Enums
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

enum ProductType { item, service }

enum TransactionType { sell, barter }

enum ServiceCategory {
  tutoring,
  homeCleaning,
  petCare,
  gardening,
  repairs,
  photography,
  cooking,
  transportation,
  webDevelopment,
  graphicDesign,
  writing,
  musicLessons,
  fitness,
  beautyServices,
  eventPlanning,
  others,
}

enum ProductAvailability {
  weekdays,
  weekends,
  flexible,
  byAppointment,
}

// Main Product Model
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
  final double? latitude;
  final double? longitude;
  final ProductStatus status;
  final int viewCount;
  final List<String> interestedUsers;
  final List<String> viewedUserIds;
  final List<String> reportedByUserIds;
  final ProductType type;
  final String? serviceCategory;
  final String? customServiceCategory;
  final int? estimatedDuration; // In hours, for services
  final double? priceRange; // Optional price reference
  final String? availabilitySchedule;
  final List<String>? skills; // Skills/qualifications for services
  final String? duration; // For backward compatibility
  final String? availability; // For backward compatibility
  final TransactionType transactionType;
  final double? price;
  final String? desiredSwapCategory;
  final bool isOwnerPremium;

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
    this.latitude,
    this.longitude,
    this.status = ProductStatus.available,
    this.viewCount = 0,
    this.interestedUsers = const [],
    this.viewedUserIds = const [],
    this.reportedByUserIds = const [],
    this.type = ProductType.item,
    this.serviceCategory,
    this.customServiceCategory,
    this.estimatedDuration,
    this.priceRange,
    this.availabilitySchedule,
    this.skills,
    this.duration,
    this.availability,
    this.transactionType = TransactionType.barter,
    this.price,
    this.desiredSwapCategory,
    this.isOwnerPremium = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json["id"] ?? '',
      title: json["title"] ?? '',
      description: json["description"] ?? '',
      category: json["category"] ?? '',
      customCategory: json["customCategory"],
      condition: json["condition"] ?? '',
      ownerId: json["ownerId"] ?? '',
      ownerName: json["ownerName"] ?? '',
      images: (json["images"] as List<dynamic>?)
              ?.map((obj) => obj.toString())
              .toList() ??
          [],
      createdAt: _parseDateTime(json["createdAt"]),
      updatedAt: _parseDateTime(json["updatedAt"]),
      isAvailable: json["isAvailable"] ?? true,
      tags: (json["tags"] as List<dynamic>?)
              ?.map((obj) => obj.toString())
              .toList() ??
          [],
      location: json["location"],
      latitude: json["latitude"]?.toDouble(),
      longitude: json["longitude"]?.toDouble(),
      status: ProductStatus.values.firstWhere(
        (status) => status.name == (json["status"] ?? "available"),
        orElse: () => ProductStatus.available,
      ),
      viewCount: json["viewCount"] ?? 0,
      interestedUsers: (json["interestedUsers"] as List<dynamic>?)
              ?.map((obj) => obj.toString())
              .toList() ??
          [],
      viewedUserIds: (json["viewedUserIds"] as List<dynamic>?)
              ?.map((obj) => obj.toString())
              .toList() ??
          [],
      reportedByUserIds: (json["reportedByUserIds"] as List<dynamic>?)
              ?.map((obj) => obj.toString())
              .toList() ??
          [],
      type: ProductType.values.firstWhere(
        (t) => t.name == (json["type"] ?? "item"),
        orElse: () => ProductType.item,
      ),
      serviceCategory: json["serviceCategory"],
      customServiceCategory: json["customServiceCategory"],
      estimatedDuration: json["estimatedDuration"],
      priceRange: json["priceRange"]?.toDouble(),
      availabilitySchedule: json["availabilitySchedule"],
      skills: (json["skills"] as List<dynamic>?)
          ?.map((obj) => obj.toString())
          .toList(),
      duration: json["duration"],
      availability: json["availability"],
      transactionType: TransactionType.values.firstWhere(
        (t) => t.name == (json["transactionType"] ?? "barter"),
        orElse: () => TransactionType.barter,
      ),
      price: json["price"]?.toDouble(),
      desiredSwapCategory: json["desiredSwapCategory"],
      isOwnerPremium: json["isOwnerPremium"] ?? false,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    } else {
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
        "latitude": latitude,
        "longitude": longitude,
        "status": status.name,
        "viewCount": viewCount,
        "interestedUsers": interestedUsers,
        "viewedUserIds": viewedUserIds,
        "reportedByUserIds": reportedByUserIds,
        "type": type.name,
        "serviceCategory": serviceCategory,
        "customServiceCategory": customServiceCategory,
        "estimatedDuration": estimatedDuration,
        "priceRange": priceRange,
        "availabilitySchedule": availabilitySchedule,
        "skills": skills,
        "duration": duration,
        "availability": availability,
        "transactionType": transactionType.name,
        "price": price,
        "desiredSwapCategory": desiredSwapCategory,
        "isOwnerPremium": isOwnerPremium,
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
    double? latitude,
    double? longitude,
    ProductStatus? status,
    int? viewCount,
    List<String>? interestedUsers,
    List<String>? viewedUserIds,
    List<String>? reportedByUserIds,
    ProductType? type,
    String? serviceCategory,
    String? customServiceCategory,
    int? estimatedDuration,
    double? priceRange,
    String? availabilitySchedule,
    List<String>? skills,
    String? duration,
    String? availability,
    TransactionType? transactionType,
    double? price,
    String? desiredSwapCategory,
    bool? isOwnerPremium,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
      interestedUsers: interestedUsers ?? this.interestedUsers,
      viewedUserIds: viewedUserIds ?? this.viewedUserIds,
      reportedByUserIds: reportedByUserIds ?? this.reportedByUserIds,
      type: type ?? this.type,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      customServiceCategory:
          customServiceCategory ?? this.customServiceCategory,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      priceRange: priceRange ?? this.priceRange,
      availabilitySchedule: availabilitySchedule ?? this.availabilitySchedule,
      skills: skills ?? this.skills,
      duration: duration ?? this.duration,
      availability: availability ?? this.availability,
      transactionType: transactionType ?? this.transactionType,
      price: price ?? this.price,
      desiredSwapCategory: desiredSwapCategory ?? this.desiredSwapCategory,
      isOwnerPremium: isOwnerPremium ?? this.isOwnerPremium,
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, title: $title, category: $category, status: $status, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Extension Methods
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

extension ProductTypeExtension on ProductType {
  String get displayName {
    switch (this) {
      case ProductType.item:
        return 'Item';
      case ProductType.service:
        return 'Service';
    }
  }
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.sell:
        return 'Sell';
      case TransactionType.barter:
        return 'Barter';
    }
  }
}

extension ServiceCategoryExtension on ServiceCategory {
  String get displayName {
    switch (this) {
      case ServiceCategory.tutoring:
        return 'Tutoring & Education';
      case ServiceCategory.homeCleaning:
        return 'Home Cleaning';
      case ServiceCategory.petCare:
        return 'Pet Care';
      case ServiceCategory.gardening:
        return 'Gardening & Landscaping';
      case ServiceCategory.repairs:
        return 'Repairs & Maintenance';
      case ServiceCategory.photography:
        return 'Photography & Videography';
      case ServiceCategory.cooking:
        return 'Cooking & Catering';
      case ServiceCategory.transportation:
        return 'Transportation';
      case ServiceCategory.webDevelopment:
        return 'Web Development';
      case ServiceCategory.graphicDesign:
        return 'Graphic Design';
      case ServiceCategory.writing:
        return 'Writing & Content';
      case ServiceCategory.musicLessons:
        return 'Music Lessons';
      case ServiceCategory.fitness:
        return 'Fitness & Training';
      case ServiceCategory.beautyServices:
        return 'Beauty Services';
      case ServiceCategory.eventPlanning:
        return 'Event Planning';
      case ServiceCategory.others:
        return 'Other Services';
    }
  }

  static List<String> get allDisplayNames {
    return ServiceCategory.values
        .map((category) => category.displayName)
        .toList();
  }

  static ServiceCategory fromDisplayName(String displayName) {
    return ServiceCategory.values.firstWhere(
      (category) => category.displayName == displayName,
      orElse: () => ServiceCategory.others,
    );
  }
}

extension ProductAvailabilityExtension on ProductAvailability {
  String get displayName {
    switch (this) {
      case ProductAvailability.weekdays:
        return 'Weekdays';
      case ProductAvailability.weekends:
        return 'Weekends';
      case ProductAvailability.flexible:
        return 'Flexible';
      case ProductAvailability.byAppointment:
        return 'By Appointment';
    }
  }

  static List<String> get allDisplayNames {
    return ProductAvailability.values
        .map((availability) => availability.displayName)
        .toList();
  }

  static ProductAvailability fromDisplayName(String displayName) {
    return ProductAvailability.values.firstWhere(
      (availability) => availability.displayName == displayName,
      orElse: () => ProductAvailability.flexible,
    );
  }
}
