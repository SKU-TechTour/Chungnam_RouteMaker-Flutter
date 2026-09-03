import '../../home_curation/models/course.dart';
import '../../home_curation/models/selected_route.dart';

class SavedCourse {
  const SavedCourse({
    required this.id,
    required this.region,
    required this.regionCode,
    required this.title,
    required this.spots,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
  });

  final String id;
  final String region;
  final String regionCode;
  final String title;
  final List<CourseSpot> spots;
  final int totalDistanceMeters;
  final int totalDurationSeconds;

  factory SavedCourse.fromJson(Map<String, dynamic> json) => SavedCourse(
    id: json['id'] as String,
    region: json['region'] as String,
    regionCode: json['regionCode'] as String,
    title: json['title'] as String,
    spots: (json['spots'] as List<dynamic>)
        .map((item) => CourseSpot.fromJson(item as Map<String, dynamic>))
        .toList(),
    totalDistanceMeters: json['totalDistanceMeters'] as int? ?? 0,
    totalDurationSeconds: json['totalDurationSeconds'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'region': region,
    'regionCode': regionCode,
    'title': title,
    'spots': spots
        .map(
          (spot) => {
            'id': spot.id,
            'name': spot.name,
            'category': spot.category,
            'latitude': spot.latitude,
            'longitude': spot.longitude,
            'imageUrl': spot.imageUrl,
            'source': spot.source,
            'address': spot.address,
            'scheduledTime': spot.scheduledTime,
          },
        )
        .toList(),
    'totalDistanceMeters': totalDistanceMeters,
    'totalDurationSeconds': totalDurationSeconds,
  };

  List<String> get places => spots.map((spot) => spot.name).toList();

  SelectedRoute toSelectedRoute() => SelectedRoute(
    title: title,
    region: regionCode,
    spots: spots,
    totalDistanceMeters: totalDistanceMeters,
    totalDurationSeconds: totalDurationSeconds,
  );

  bool hasSameRoute(SavedCourse other) {
    if (id != other.id || spots.length != other.spots.length) return false;
    for (var index = 0; index < spots.length; index++) {
      if (spots[index].id != other.spots[index].id) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) => other is SavedCourse && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
