import 'package:geolocator/geolocator.dart';

/// 기기 GPS 좌표 획득 유틸.
///
/// [map_search] feature의 ViewModel에서 호출합니다.
/// 현재 좌표는 서버로 전송하지 않고 기기 안에서 거리 계산에만 사용합니다.
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

  double distanceInMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) => Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
}
