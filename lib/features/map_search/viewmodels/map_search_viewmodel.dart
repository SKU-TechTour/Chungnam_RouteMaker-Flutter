import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/constants/api_constants.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/features/map_search/models/place.dart';
import 'package:flutterprojects/features/map_search/viewmodels/map_search_state.dart';

/// [SB 화면 3] 반려동물/유모차 필터 체크박스 상태 ViewModel.
class MapSearchViewModel extends Notifier<MapSearchState> {
  @override
  MapSearchState build() => const MapSearchState();

  void setRegion(String region) => state = state.copyWith(region: region);
  void togglePetFriendly(bool value) =>
      state = state.copyWith(petFriendly: value);
  void toggleStrollerAccessible(bool value) =>
      state = state.copyWith(strollerAccessible: value);
  void toggleParking(bool value) => state = state.copyWith(parking: value);

  Future<void> searchNearby() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final request = PlaceFilterRequest(
      region: state.region,
      petFriendly: state.petFriendly,
      strollerAccessible: state.strollerAccessible,
      largeParking: state.parking,
    );
    List<Place> places;
    final repository = ref.read(placeRepositoryProvider);
    if (ApiConstants.useMockData) {
      places = await repository.loadMockPlaces(request);
    } else {
      try {
        places = await repository.filterPlaces(request);
      } catch (_) {
        places = await repository.loadMockPlaces(request);
      }
    }

    final currentLat = state.currentLat;
    final currentLng = state.currentLng;
    if (currentLat != null && currentLng != null) {
      places = _sortByDistance(places, currentLat, currentLng);
    }
    state = state.copyWith(places: places, isLoading: false);
  }

  void applyDeviceLocation(double lat, double lng) {
    state = state.copyWith(
      places: _sortByDistance(state.places, lat, lng),
      currentLat: lat,
      currentLng: lng,
    );
  }

  List<Place> _sortByDistance(List<Place> places, double lat, double lng) {
    final locationUtil = ref.read(locationUtilProvider);
    final sorted = places
        .map(
          (place) => place.withDistance(
            locationUtil.distanceInMeters(
              fromLat: lat,
              fromLng: lng,
              toLat: place.lat,
              toLng: place.lng,
            ),
          ),
        )
        .toList();
    sorted.sort(
      (a, b) => (a.distanceMeters ?? double.infinity).compareTo(
        b.distanceMeters ?? double.infinity,
      ),
    );
    return sorted;
  }
}
