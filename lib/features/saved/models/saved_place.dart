import '../../map_search/models/place.dart';

class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.regionCode,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.address,
    this.petFriendly = false,
  });

  factory SavedPlace.fromPlace(Place place, String regionCode) => SavedPlace(
    id: place.id,
    regionCode: regionCode,
    name: place.name,
    type: place.type,
    latitude: place.lat,
    longitude: place.lng,
    imageUrl: place.imageUrl,
    address: place.address,
    petFriendly: place.petFriendly,
  );

  factory SavedPlace.fromJson(Map<String, dynamic> json) => SavedPlace(
    id: json['id'] as String,
    regionCode: json['regionCode'] as String? ?? 'NONSAN',
    name: json['name'] as String,
    type: PlaceType.values.firstWhere(
      (type) => type.name == json['type'],
      orElse: () => PlaceType.tourist,
    ),
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    imageUrl: json['imageUrl'] as String?,
    address: json['address'] as String?,
    petFriendly: json['petFriendly'] as bool? ?? false,
  );

  final String id;
  final String regionCode;
  final String name;
  final PlaceType type;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? address;
  final bool petFriendly;

  String get storageKey => '$regionCode:$id';

  String get regionLabel => switch (regionCode) {
    'NONSAN' => '논산',
    'GONGJU' => '공주',
    'BUYEO' => '부여',
    _ => regionCode,
  };

  String get categoryLabel => switch (type) {
    PlaceType.restaurant => '맛집',
    PlaceType.accommodation => '숙소',
    PlaceType.cafe => '카페',
    PlaceType.tourist => '관광지',
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'regionCode': regionCode,
    'name': name,
    'type': type.name,
    'latitude': latitude,
    'longitude': longitude,
    'imageUrl': imageUrl,
    'address': address,
    'petFriendly': petFriendly,
  };
}
