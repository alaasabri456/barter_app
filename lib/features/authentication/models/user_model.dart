class UserModel {
  static UserModel? currentUser;
  String id;
  String name;
  String email;
  List<String> favouriteProductIds;
  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.favouriteProductIds,
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
      );
  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "favouriteProductIds": favouriteProductIds,
  };
}
