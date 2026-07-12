import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/features/map_search/models/place.dart';
import 'package:flutterprojects/features/map_search/viewmodels/map_search_state.dart';

const _mockPlaces = [
  Place(id: 'p1', name: '공산성', type: PlaceType.tourist, lat: 36.4596, lng: 127.1128),
  Place(id: 'p2', name: '중동식당', type: PlaceType.restaurant, lat: 36.4465, lng: 127.1191),
  Place(id: 'p3', name: '제민천카페', type: PlaceType.cafe, lat: 36.4444, lng: 127.1200),
];

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
    } catch (_) {
      // 백엔드/GPS 미연결 시 목업 데이터로 폴백
      state = state.copyWith(places: _mockPlaces, isLoading: false);
    }
  }
}
