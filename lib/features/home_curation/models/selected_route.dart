import 'course.dart';

class SelectedRoute {
  const SelectedRoute({
    required this.title,
    required this.region,
    required this.spots,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
  });

  final String title;
  final String region;
  final List<CourseSpot> spots;
  final int totalDistanceMeters;
  final int totalDurationSeconds;
}

class RouteMetrics {
  const RouteMetrics({
    required this.distanceMeters,
    required this.durationSeconds,
    this.path = const [],
    this.guides = const [],
  });

  final int distanceMeters;
  final int durationSeconds;
  final List<RoutePathPoint> path;
  final List<RouteGuideStep> guides;
}

class RoutePathPoint {
  const RoutePathPoint({required this.latitude, required this.longitude});

  factory RoutePathPoint.fromJson(Map<String, dynamic> json) => RoutePathPoint(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );

  final double latitude;
  final double longitude;
}

class RouteGuideStep {
  const RouteGuideStep({
    required this.instruction,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory RouteGuideStep.fromJson(Map<String, dynamic> json) => RouteGuideStep(
    instruction: json['instruction'] as String? ?? '이동',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    distanceMeters: (json['distanceMeters'] as num?)?.round() ?? 0,
    durationSeconds: (json['durationSeconds'] as num?)?.round() ?? 0,
  );

  final String instruction;
  final double latitude;
  final double longitude;
  final int distanceMeters;
  final int durationSeconds;
}
