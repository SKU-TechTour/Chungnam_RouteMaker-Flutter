class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final bool isMilitary;
  final DateTime? trainingStartDate;
  final String? unitLocation;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.isMilitary = false,
    this.trainingStartDate,
    this.unitLocation,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        profileImage: json['profileImage'] as String?,
        isMilitary: json['isMilitary'] as bool? ?? false,
        trainingStartDate: json['trainingStartDate'] != null
            ? DateTime.parse(json['trainingStartDate'] as String)
            : null,
        unitLocation: json['unitLocation'] as String?,
      );
}
