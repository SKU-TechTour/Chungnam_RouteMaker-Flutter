import 'package:geolocator/geolocator.dart';

/// 기기 GPS 좌표 획득 유틸.
///
/// [map_search] feature의 ViewModel에서 호출하여
/// 주변 장소 필터 API 요청에 lat/lng를 포함합니다.
class LocationUtil {
  const LocationUtil();

  Future<({double lat, double lng})> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    final position = await Geolocator.getCurrentPosition();
    return (lat: position.latitude, lng: position.longitude);
  }
}
