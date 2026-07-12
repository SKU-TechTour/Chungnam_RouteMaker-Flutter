import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/features/map_search/models/place.dart';
import 'package:flutterprojects/features/map_search/viewmodels/map_search_state.dart';

/// [SB 화면 3] 반려동물/유모차 필터 체크박스 상태 ViewModel.
class MapSearchViewModel extends Notifier<MapSearchState> {
  @override
  MapSearchState build() => const MapSearchState();

  void setRegion(String region) => state = state.copyWith(region: region);
  void togglePetFriendly(bool value) => state = state.copyWith(petFriendly: value);
  void toggleStrollerAccessible(bool value) => state = state.copyWith(strollerAccessible: value);
  void toggleParking(bool value) => state = state.copyWith(parking: value);

  Future<void> searchNearby() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final location = await ref.read(locationUtilProvider).getCurrentPosition();
      final places = await ref.read(placeRepositoryProvider).filterPlaces(
            PlaceFilterRequest(
              lat: location.lat,
              lng: location.lng,
              petFriendly: state.petFriendly,
              strollerAccessible: state.strollerAccessible,
            ),
          );
      state = state.copyWith(places: places, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
