import 'package:geolocator/geolocator.dart';

enum AppLocationPermission { granted, denied, deniedForever }

class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();
}

class LocationPermissionRequiredException implements Exception {
  const LocationPermissionRequiredException();
}

/// 기기 GPS 좌표 획득 유틸.
///
/// [map_search] feature의 ViewModel에서 호출합니다.
/// 현재 좌표는 서버로 전송하지 않고 기기 안에서 거리 계산에만 사용합니다.
class LocationUtil {
  const LocationUtil();

  Future<AppLocationPermission> permissionStatus() async =>
      _mapPermission(await Geolocator.checkPermission());

  Future<AppLocationPermission> requestPermission() async =>
      _mapPermission(await Geolocator.requestPermission());

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<({double lat, double lng})> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    if (await permissionStatus() != AppLocationPermission.granted) {
      // 런타임 권한 창은 화면의 사전 안내에 동의한 뒤에만 요청합니다.
      throw const LocationPermissionRequiredException();
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return (lat: position.latitude, lng: position.longitude);
  }

  double distanceInMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) => Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);

  AppLocationPermission _mapPermission(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => AppLocationPermission.granted,
      LocationPermission.deniedForever => AppLocationPermission.deniedForever,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => AppLocationPermission.denied,
    };
  }
}
