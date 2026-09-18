import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class ExternalMapLinks {
  static const appId = 'com.techtour.flutterprojects';

  static Uri kakaoPlace({
    required String name,
    required double latitude,
    required double longitude,
  }) => Uri.parse(
    'https://map.kakao.com/link/map/'
    '${Uri.encodeComponent(name)},$latitude,$longitude',
  );

  static Uri naverPlaceApp({
    required String name,
    required double latitude,
    required double longitude,
  }) => Uri(
    scheme: 'nmap',
    host: 'place',
    queryParameters: {
      'lat': '$latitude',
      'lng': '$longitude',
      'name': name,
      'appname': appId,
    },
  );

  static Uri naverPlaceWeb(String name) =>
      Uri.https('map.naver.com', '/p/search/$name');
}

class ExternalMapButtons extends StatelessWidget {
  const ExternalMapButtons({
    super.key,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;

  bool get _hasValidCoordinates =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      !(latitude == 0 && longitude == 0);

  Future<void> _openKakao(BuildContext context) async {
    final opened = await launchUrl(
      ExternalMapLinks.kakaoPlace(
        name: name,
        latitude: latitude,
        longitude: longitude,
      ),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) _showOpenError(context, '카카오맵');
  }

  Future<void> _openNaver(BuildContext context) async {
    var opened = false;
    if (!kIsWeb) {
      opened = await launchUrl(
        ExternalMapLinks.naverPlaceApp(
          name: name,
          latitude: latitude,
          longitude: longitude,
        ),
        mode: LaunchMode.externalApplication,
      );
    }
    if (!opened) {
      opened = await launchUrl(
        ExternalMapLinks.naverPlaceWeb(name),
        mode: LaunchMode.externalApplication,
      );
    }
    if (!opened && context.mounted) _showOpenError(context, '네이버지도');
  }

  void _showOpenError(BuildContext context, String mapName) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$mapName을 열 수 없어요.')));
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasValidCoordinates) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openNaver(context),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('네이버지도'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF03C75A),
              side: const BorderSide(color: Color(0xFFB9E9CA)),
              minimumSize: const Size(0, 48),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openKakao(context),
            icon: const Icon(Icons.location_on_outlined, size: 18),
            label: const Text('카카오맵'),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF9A6B00),
              side: const BorderSide(color: Color(0xFFFFD85A)),
              minimumSize: const Size(0, 48),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
