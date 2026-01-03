enum UserRole {
  user,
  admin,
  moderator,
  premium;

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
    }
  }
}

class UserModel {
  static UserModel? currentUser;
  String id;
  String name;
  String email;
  List<String> favouriteProductIds;
  UserRole role;
  String? fcmToken;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.favouriteProductIds,
    this.role = UserRole.user,
    this.fcmToken,
  });

  UserModel.fromJson(Map<String, dynamic> json)
    : this(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        favouriteProductIds:
            (json["favouriteProductIds"] as List<dynamic>?)
                ?.map((obj) => obj.toString())
                .toList() ??
            [],
        role: _parseRole(json["role"]),
        fcmToken: json["fcmToken"],
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

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "favouriteProductIds": favouriteProductIds,
    "role": role.name,
    "fcmToken": fcmToken,
  };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    List<String>? favouriteProductIds,
    UserRole? role,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      favouriteProductIds: favouriteProductIds ?? this.favouriteProductIds,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  // Permission helper methods
  bool get isAdmin => role == UserRole.admin;
  bool get isModerator => role == UserRole.moderator;
  bool get isPremium => role == UserRole.premium;
  bool get canModerateContent => isAdmin || isModerator;
  bool get canAccessAdminPanel => isAdmin;
}
