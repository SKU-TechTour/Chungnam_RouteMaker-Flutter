import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/features/map_search/models/place.dart';
import 'package:flutterprojects/features/map_search/viewmodels/map_search_state.dart';

const _fallbackPlaces = {
  'NONSAN': [
    Place(
      id: 'nonsan-training-center',
      name: '육군훈련소',
      type: PlaceType.tourist,
      lat: 36.1119731,
      lng: 127.1083526,
    ),
    Place(
      id: 'nonsan-gwanchoksa',
      name: '관촉사',
      type: PlaceType.tourist,
      lat: 36.1884477,
      lng: 127.1130246,
    ),
    Place(
      id: 'nonsan-tapjeong',
      name: '탑정호',
      type: PlaceType.tourist,
      lat: 36.1783768,
      lng: 127.1798397,
    ),
    Place(
      id: 'nonsan-ganggyeong-club',
      name: '강경구락부',
      type: PlaceType.cafe,
      lat: 36.1621613,
      lng: 127.0156316,
    ),
  ],
  'GONGJU': [
    Place(
      id: 'gongju-gongsanseong',
      name: '공산성',
      type: PlaceType.tourist,
      lat: 36.4631426,
      lng: 127.1264411,
    ),
    Place(
      id: 'gongju-national-museum',
      name: '국립공주박물관',
      type: PlaceType.tourist,
      lat: 36.4655287,
      lng: 127.1122874,
    ),
    Place(
      id: 'gongju-hanok-village',
      name: '공주한옥마을',
      type: PlaceType.tourist,
      lat: 36.4647117,
      lng: 127.1087143,
    ),
    Place(
      id: 'gongju-seokjangri',
      name: '석장리박물관',
      type: PlaceType.tourist,
      lat: 36.4476254,
      lng: 127.1895492,
    ),
  ],
  'BUYEO': [
    Place(
      id: 'buyeo-culture-land',
      name: '백제문화단지',
      type: PlaceType.tourist,
      lat: 36.3073820,
      lng: 126.9072410,
    ),
    Place(
      id: 'buyeo-busosanseong',
      name: '부소산성',
      type: PlaceType.tourist,
      lat: 36.2892424,
      lng: 126.9151865,
    ),
    Place(
      id: 'buyeo-national-museum',
      name: '국립부여박물관',
      type: PlaceType.tourist,
      lat: 36.2763114,
      lng: 126.9190510,
    ),
    Place(
      id: 'buyeo-jeongnimsa',
      name: '정림사지박물관',
      type: PlaceType.tourist,
      lat: 36.2792287,
      lng: 126.9151939,
    ),
  ],
};

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
    List<Place> places;
    try {
      places = await ref
          .read(placeRepositoryProvider)
          .filterPlaces(
            PlaceFilterRequest(
              region: state.region,
              petFriendly: state.petFriendly,
              strollerAccessible: state.strollerAccessible,
              largeParking: state.parking,
            ),
          );
    } catch (_) {
      // 백엔드 미연결 시 검증된 실제 장소 좌표로 폴백합니다.
      places = _fallbackPlaces[state.region] ?? const [];
    }

    try {
      final current = await ref.read(locationUtilProvider).getCurrentPosition();
      places = _sortByDistance(places, current.lat, current.lng);
      state = state.copyWith(
        places: places,
        isLoading: false,
        currentLat: current.lat,
        currentLng: current.lng,
      );
    } catch (_) {
      state = state.copyWith(places: places, isLoading: false);
    }
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
