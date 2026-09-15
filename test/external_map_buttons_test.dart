import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterprojects/core/theme/app_theme.dart';
import 'package:flutterprojects/core/widgets/external_map_buttons.dart';

void main() {
  test('카카오맵 장소 링크에 이름과 위경도를 포함한다', () {
    final uri = ExternalMapLinks.kakaoPlace(
      name: '공산성',
      latitude: 36.4623,
      longitude: 127.1277,
    );

    expect(uri.host, 'map.kakao.com');
    expect(uri.pathSegments, ['link', 'map', '공산성,36.4623,127.1277']);
  });

  test('네이버지도 앱 링크에 앱 ID와 장소 좌표를 포함한다', () {
    final uri = ExternalMapLinks.naverPlaceApp(
      name: '공산성',
      latitude: 36.4623,
      longitude: 127.1277,
    );

    expect(uri.scheme, 'nmap');
    expect(uri.host, 'place');
    expect(uri.queryParameters['name'], '공산성');
    expect(uri.queryParameters['lat'], '36.4623');
    expect(uri.queryParameters['lng'], '127.1277');
    expect(uri.queryParameters['appname'], 'com.techtour.flutterprojects');
  });

  testWidgets('유효한 좌표가 있으면 두 지도 버튼을 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: ExternalMapButtons(
            name: '공산성',
            latitude: 36.4623,
            longitude: 127.1277,
          ),
        ),
      ),
    );

    expect(find.text('네이버지도'), findsOneWidget);
    expect(find.text('카카오맵'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
