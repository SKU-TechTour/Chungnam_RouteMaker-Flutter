enum Region { nonsan, gongju, buyeo }

extension RegionLabel on Region {
  String get label {
    switch (this) {
      case Region.nonsan: return '논산';
      case Region.gongju: return '공주';
      case Region.buyeo: return '부여';
    }
  }

  String get tag {
    switch (this) {
      case Region.nonsan: return '단기 고효율';
      case Region.gongju: return '로컬 데이트';
      case Region.buyeo: return '가족 힐링';
    }
  }
}

class PlaceItem {
  final String id;
  final String name;
  final String category; // sight / food / cafe
  final String imageUrl;
  final double lat;
  final double lng;
  final bool hasMilitaryDiscount;

  const PlaceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    this.hasMilitaryDiscount = false,
  });

  factory PlaceItem.fromJson(Map<String, dynamic> json) => PlaceItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        imageUrl: json['imageUrl'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        hasMilitaryDiscount: json['hasMilitaryDiscount'] as bool? ?? false,
      );
}

class CourseModel {
  final String id;
  final Region region;
  final String title;
  final String description;
  final PlaceItem sight;
  final PlaceItem food;
  final PlaceItem cafe;
  final bool isIndoor;

  const CourseModel({
    required this.id,
    required this.region,
    required this.title,
    required this.description,
    required this.sight,
    required this.food,
    required this.cafe,
    this.isIndoor = false,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        id: json['id'] as String,
        region: Region.values.firstWhere(
          (r) => r.name == (json['region'] as String).toLowerCase(),
          orElse: () => Region.gongju,
        ),
        title: json['title'] as String,
        description: json['description'] as String,
        sight: PlaceItem.fromJson(json['sight'] as Map<String, dynamic>),
        food: PlaceItem.fromJson(json['food'] as Map<String, dynamic>),
        cafe: PlaceItem.fromJson(json['cafe'] as Map<String, dynamic>),
        isIndoor: json['isIndoor'] as bool? ?? false,
      );
}
