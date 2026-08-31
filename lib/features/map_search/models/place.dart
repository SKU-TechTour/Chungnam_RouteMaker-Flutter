/// 주변 관광지/식당/카페 모델.
///
/// Spring `POST /api/places/filter` 요청·응답 필드와 매핑합니다.
enum PlaceType { tourist, restaurant, accommodation, cafe }

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    this.petFriendly = false,
    this.strollerAccessible = false,
    this.distanceMeters,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String?;
    return Place(
      id: json['id'].toString(),
      name: json['name'] as String,
      type: switch (category) {
        'RESTAURANT' => PlaceType.restaurant,
        'ACCOMMODATION' => PlaceType.accommodation,
        'CAFE' => PlaceType.cafe,
        _ => PlaceType.tourist,
      },
      lat: (json['latitude'] as num).toDouble(),
      lng: (json['longitude'] as num).toDouble(),
      petFriendly: json['petFriendly'] as bool? ?? false,
      strollerAccessible: json['strollerAccessible'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final PlaceType type;
  final double lat;
  final double lng;
  final bool petFriendly;
  final bool strollerAccessible;
  final double? distanceMeters;

  Place withDistance(double value) => Place(
    id: id,
    name: name,
    type: type,
    lat: lat,
    lng: lng,
    petFriendly: petFriendly,
    strollerAccessible: strollerAccessible,
    distanceMeters: value,
  );

  String? get formattedDistance {
    final distance = distanceMeters;
    if (distance == null) return null;
    if (distance < 1000) return '${distance.round()}m';
    return '${(distance / 1000).toStringAsFixed(1)}km';
  }
}

/// 필터 API 요청 body
class PlaceFilterRequest {
  const PlaceFilterRequest({
    required this.region,
    this.petFriendly = false,
    this.strollerAccessible = false,
    this.largeParking = false,
  });

  final String region;
  final bool petFriendly;
  final bool strollerAccessible;
  final bool largeParking;

  Map<String, dynamic> toQueryParameters() => {
    'region': region,
    'petFriendly': petFriendly,
    'strollerAccessible': strollerAccessible,
    'largeParking': largeParking,
  };
}
