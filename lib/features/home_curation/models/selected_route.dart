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
  });

  final int distanceMeters;
  final int durationSeconds;
}
