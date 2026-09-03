import '../../travel_preferences/models/travel_preferences.dart';
import 'course.dart';
import 'selected_route.dart';

class HomeSession {
  const HomeSession({
    required this.regionIndex,
    required this.preferences,
    required this.preferenceSignature,
    required this.editableSpots,
    required this.selectedVariant,
    this.previewMetrics,
  });

  final int regionIndex;
  final TravelPreferences preferences;
  final String preferenceSignature;
  final List<CourseSpot> editableSpots;
  final int selectedVariant;
  final RouteMetrics? previewMetrics;
}

String travelPreferenceSignature(TravelPreferences value) {
  final concepts = value.concepts.map((concept) => concept.name).toList()
    ..sort();
  return '${value.party.name}|${value.duration.name}|'
      '${value.routeTemplate.name}|${concepts.join(',')}';
}
