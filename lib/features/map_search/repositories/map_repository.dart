import '../models/place_filter_model.dart';

class MapRepository {
  Future<List<MapPlaceModel>> filterPlaces(PlaceFilterModel filter) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: 백엔드 연동 시 DioClient로 교체
    final all = [
      MapPlaceModel(id: '1', name: '공산성', category: 'sight', lat: 36.4596, lng: 127.1128),
      MapPlaceModel(id: '2', name: '중동식당', category: 'food', lat: 36.4465, lng: 127.1191),
      MapPlaceModel(id: '3', name: '제민천카페', category: 'cafe', lat: 36.4444, lng: 127.1200),
      MapPlaceModel(id: '4', name: '공주박물관', category: 'sight', lat: 36.4563, lng: 127.1100),
      MapPlaceModel(id: '5', name: '관촉사', category: 'sight', lat: 36.1985, lng: 127.0922),
      MapPlaceModel(id: '6', name: '연무대 고기집', category: 'food', lat: 36.2004, lng: 127.0956),
      MapPlaceModel(id: '7', name: '부소산성', category: 'sight', lat: 36.2757, lng: 126.9100),
      MapPlaceModel(id: '8', name: '백마강뷰 카페', category: 'cafe', lat: 36.2720, lng: 126.9080),
    ];

    final regionFilter = switch (filter.region) {
      'NONSAN' => (MapPlaceModel p) => p.lat > 36.15 && p.lat < 36.25,
      'BUYEO' => (MapPlaceModel p) => p.lat > 36.25 && p.lat < 36.30,
      _ => (MapPlaceModel p) => p.lat > 36.40,
    };

    return all.where(regionFilter).toList();
  }
}
