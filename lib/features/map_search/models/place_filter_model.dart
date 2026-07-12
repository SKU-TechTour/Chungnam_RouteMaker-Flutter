class PlaceFilterModel {
  final bool stroller;
  final bool pet;
  final bool parking;
  final String region;

  const PlaceFilterModel({
    this.stroller = false,
    this.pet = false,
    this.parking = false,
    this.region = 'GONGJU',
  });

  PlaceFilterModel copyWith({
    bool? stroller,
    bool? pet,
    bool? parking,
    String? region,
  }) =>
      PlaceFilterModel(
        stroller: stroller ?? this.stroller,
        pet: pet ?? this.pet,
        parking: parking ?? this.parking,
        region: region ?? this.region,
      );

  Map<String, dynamic> toJson() => {
        'stroller': stroller,
        'pet': pet,
        'parking': parking,
        'region': region,
      };
}

class MapPlaceModel {
  final String id;
  final String name;
  final String category;
  final double lat;
  final double lng;
  final String? imageUrl;

  const MapPlaceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    this.imageUrl,
  });

  factory MapPlaceModel.fromJson(Map<String, dynamic> json) => MapPlaceModel(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        imageUrl: json['imageUrl'] as String?,
      );
}
