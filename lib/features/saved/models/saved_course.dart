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
    this.bookmarkCount = 0,
  });

  final String id;
  final String region;
  final String regionCode;
  final String title;
  final List<CourseSpot> spots;
  final int totalDistanceMeters;
  final int totalDurationSeconds;
  final int bookmarkCount;

  String get routeKey =>
      '$regionCode:${spots.map((spot) => spot.id).join('-')}';

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
    bookmarkCount: json['bookmarkCount'] as int? ?? 0,
  );

  factory SavedCourse.fromPopularApi(Map<String, dynamic> json) => SavedCourse(
    id: json['routeKey'] as String,
    region: _regionLabel(json['region'] as String? ?? ''),
    regionCode: json['region'] as String? ?? '',
    title: json['title'] as String? ?? '인기 코스',
    spots: (json['spots'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CourseSpot.fromJson)
        .toList(growable: false),
    totalDistanceMeters: (json['totalDistanceMeters'] as num?)?.round() ?? 0,
    totalDurationSeconds: (json['totalDurationSeconds'] as num?)?.round() ?? 0,
    bookmarkCount: (json['bookmarkCount'] as num?)?.round() ?? 0,
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
    'bookmarkCount': bookmarkCount,
  };

  Map<String, dynamic> toBookmarkRequest() => {
    'routeKey': routeKey,
    'region': regionCode,
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
        .toList(growable: false),
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
    if (routeKey != other.routeKey || spots.length != other.spots.length) {
      return false;
    }
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

String _regionLabel(String code) => switch (code) {
  'NONSAN' => '논산',
  'GONGJU' => '공주',
  'BUYEO' => '부여',
  _ => code,
};
