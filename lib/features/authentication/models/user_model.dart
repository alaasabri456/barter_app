enum UserRole {
  user,
  admin,
  moderator,
  premium,
  agent;

  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.admin:
        return 'Admin';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.premium:
        return 'Premium';
      case UserRole.agent:
        return 'Agent';
    }
  }
}

class UserModel {
  static UserModel? currentUser;
  static bool get isGuest => currentUser?.isAnonymous ?? false;

  String id;
  String name;
  String email;
  List<String> favouriteProductIds;
  List<String> blockedUserIds;
  UserRole role;
  String? fcmToken;
  String languageCode;
  String? profileImageUrl;
  bool isAnonymous;
  bool is2faEnabled;
  bool isPremiumActive;
  DateTime? premiumExpiresAt;
  double walletBalance;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.favouriteProductIds,
    this.blockedUserIds = const [],
    this.role = UserRole.user,
    this.fcmToken,
    this.languageCode = 'en',
    this.profileImageUrl,
    this.isAnonymous = false,
    this.is2faEnabled = false,
    this.isPremiumActive = false,
    this.premiumExpiresAt,
    this.walletBalance = 0.0,
  });

  factory UserModel.guest(String uid) {
    return UserModel(
      id: uid,
      email: 'guest@barter.app',
      name: 'Guest User',
      favouriteProductIds: [],
      blockedUserIds: [],
      languageCode: 'en',
      isAnonymous: true,
      is2faEnabled: false,
      isPremiumActive: false,
      walletBalance: 0.0,
    );
  }

  UserModel.fromJson(Map<String, dynamic> json)
      : this(
          id: json["id"],
          name: json["name"],
          email: json["email"],
          favouriteProductIds: (json["favouriteProductIds"] as List<dynamic>?)
                  ?.map((obj) => obj.toString())
                  .toList() ??
              [],
          blockedUserIds: (json["blockedUserIds"] as List<dynamic>?)
                  ?.map((obj) => obj.toString())
                  .toList() ??
              [],
          role: _parseRole(json["role"]),
          fcmToken: json["fcmToken"],
          languageCode: json["languageCode"] ?? 'en',
          profileImageUrl: json["profileImageUrl"],
          isAnonymous: json["isAnonymous"] ?? false,
          is2faEnabled: json["is2faEnabled"] ?? false,
          isPremiumActive: json["isPremiumActive"] ?? false,
          premiumExpiresAt: _parsePremiumExpiry(json["premiumExpiresAt"]),
          walletBalance: (json["walletBalance"] as num?)?.toDouble() ?? 0.0,
        );

  static UserRole _parseRole(dynamic roleValue) {
    if (roleValue == null) return UserRole.user;
    if (roleValue is String) {
      try {
        return UserRole.values.firstWhere(
          (e) => e.name == roleValue,
          orElse: () => UserRole.user,
        );
      } catch (e) {
        return UserRole.user;
      }
    }
    return UserRole.user;
  }

  static DateTime? _parsePremiumExpiry(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      return (value as dynamic).toDate();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "email": email,
        "favouriteProductIds": favouriteProductIds,
        "blockedUserIds": blockedUserIds,
        "role": role.name,
        "fcmToken": fcmToken,
        "languageCode": languageCode,
        "profileImageUrl": profileImageUrl,
        "isAnonymous": isAnonymous,
        "is2faEnabled": is2faEnabled,
        "isPremiumActive": isPremiumActive,
        "premiumExpiresAt": premiumExpiresAt?.toIso8601String(),
        "walletBalance": walletBalance,
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    List<String>? favouriteProductIds,
    List<String>? blockedUserIds,
    UserRole? role,
    String? fcmToken,
    String? languageCode,
    String? profileImageUrl,
    bool? isAnonymous,
    bool? is2faEnabled,
    bool? isPremiumActive,
    DateTime? premiumExpiresAt,
    double? walletBalance,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      favouriteProductIds: favouriteProductIds ?? this.favouriteProductIds,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      languageCode: languageCode ?? this.languageCode,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      is2faEnabled: is2faEnabled ?? this.is2faEnabled,
      isPremiumActive: isPremiumActive ?? this.isPremiumActive,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      walletBalance: walletBalance ?? this.walletBalance,
    );
  }

  // Permission helper methods
  bool get isAdmin => role == UserRole.admin;
  bool get isModerator => role == UserRole.moderator;
  bool get isAgent => role == UserRole.agent;
  /// Returns `true` if the user has an active premium subscription
  /// (either via role or via time-based subscription).
  bool get isPremium =>
      role == UserRole.premium ||
      (isPremiumActive &&
          premiumExpiresAt != null &&
          DateTime.now().isBefore(premiumExpiresAt!));
  bool get canModerateContent => isAdmin || isModerator;
  bool get canAccessAdminPanel => isAdmin;
}
