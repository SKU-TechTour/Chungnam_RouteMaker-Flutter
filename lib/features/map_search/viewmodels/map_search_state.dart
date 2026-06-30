import 'package:flutterprojects/features/map_search/models/place.dart';

/// [SB 화면 3] 지도·필터 View 상태.
class MapSearchState {
  const MapSearchState({
    this.places = const [],
    this.petFriendly = false,
    this.strollerAccessible = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Place> places;
  final bool petFriendly;
  final bool strollerAccessible;
  final bool isLoading;
  final String? errorMessage;

  MapSearchState copyWith({
    List<Place>? places,
    bool? petFriendly,
    bool? strollerAccessible,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MapSearchState(
      places: places ?? this.places,
      petFriendly: petFriendly ?? this.petFriendly,
      strollerAccessible: strollerAccessible ?? this.strollerAccessible,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
