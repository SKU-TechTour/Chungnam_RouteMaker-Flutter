class StampModel {
  final String id;
  final String region;
  final String courseName;
  final DateTime completedAt;

  const StampModel({
    required this.id,
    required this.region,
    required this.courseName,
    required this.completedAt,
  });

  factory StampModel.fromJson(Map<String, dynamic> json) => StampModel(
        id: json['id'] as String,
        region: json['region'] as String,
        courseName: json['courseName'] as String,
        completedAt: DateTime.parse(json['completedAt'] as String),
      );
}

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final bool isChakPartner;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.isChakPartner = false,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) => BadgeModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        imageUrl: json['imageUrl'] as String?,
        isChakPartner: json['isChakPartner'] as bool? ?? false,
      );
}

class RewardModel {
  final List<StampModel> stamps;
  final List<BadgeModel> badges;
  final String? shareCardUrl;

  const RewardModel({
    required this.stamps,
    required this.badges,
    this.shareCardUrl,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) => RewardModel(
        stamps: (json['stamps'] as List)
            .map((e) => StampModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        badges: (json['badges'] as List)
            .map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        shareCardUrl: json['shareCardUrl'] as String?,
      );
}
