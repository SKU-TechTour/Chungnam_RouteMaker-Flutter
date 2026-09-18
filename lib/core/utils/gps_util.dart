import 'package:geolocator/geolocator.dart';

class GpsUtil {
  static Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    final permission = await Geolocator.checkPermission();
    // 사용자에게 목적을 알리는 화면 없이 시스템 권한 창을 직접 띄우지 않는다.
    // 새 위치 기능은 LocationUtil과 MapScreen의 사전 안내 흐름을 사용해야 한다.
    if (permission == LocationPermission.denied) return null;
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
