/// 주변 관광지/식당/카페 모델.
///
/// Spring `POST /api/places/filter` 요청·응답 필드와 매핑합니다.
enum PlaceType { tourist, restaurant, cafe }

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    this.petFriendly = false,
    this.strollerAccessible = false,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      type: PlaceType.values.byName(json['type'] as String),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
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
}

/// 필터 API 요청 body
class PlaceFilterRequest {
  const PlaceFilterRequest({
    required this.lat,
    required this.lng,
    this.petFriendly = false,
    this.strollerAccessible = false,
  });

  final double lat;
  final double lng;
  final bool petFriendly;
  final bool strollerAccessible;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'petFriendly': petFriendly,
        'strollerAccessible': strollerAccessible,
      };
}
