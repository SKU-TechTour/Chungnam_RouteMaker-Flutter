import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/core/utils/location_util.dart';
import 'package:flutterprojects/features/home_curation/models/course.dart';
import 'package:flutterprojects/features/home_curation/models/selected_route.dart';
import 'package:flutterprojects/features/home_curation/repositories/course_repository.dart';
import 'package:flutterprojects/features/map_search/views/map_screen.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('선택한 코스로 지도 화면에 진입하면 경유지와 시작 버튼이 표시된다', (tester) async {
    final route = SelectedRoute(
      title: '논산 입영 테스트 코스',
      region: 'NONSAN',
      spots: const [
        CourseSpot(
          id: '1',
          name: '점심 식당',
          category: 'RESTAURANT',
          latitude: 36.1755,
          longitude: 127.1541,
        ),
        CourseSpot(
          id: '2',
          name: '족욕 카페',
          category: 'CAFE',
          latitude: 36.1586,
          longitude: 127.1009,
        ),
        CourseSpot(
          id: '-1',
          name: '육군훈련소',
          category: 'HERITAGE',
          latitude: 36.1119,
          longitude: 127.1083,
        ),
      ],
      totalDistanceMeters: 14826,
      totalDurationSeconds: 1669,
    );

    final router = GoRouter(
      initialLocation: '/launch',
      routes: [
        GoRoute(
          path: '/launch',
          builder: (context, state) => Consumer(
            builder: (context, ref, _) => Material(
              child: Center(
                child: FilledButton(
                  onPressed: () {
                    ref.read(selectedRouteProvider.notifier).state = route;
                    context.go('/map', extra: route);
                  },
                  child: const Text('이 루트 시작하기'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => MapScreen(
            initialRoute: state.extra is SelectedRoute
                ? state.extra! as SelectedRoute
                : null,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseRepositoryProvider.overrideWithValue(_FakeCourseRepository()),
          locationUtilProvider.overrideWithValue(const _FakeLocationUtil()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('이 루트 시작하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('논산 입영 테스트 코스'), findsOneWidget);
    expect(find.text('선택한 3곳을 순서대로 연결했어요'), findsOneWidget);
    expect(find.text('코스 여행 시작'), findsOneWidget);
    expect(find.text('오늘의 연결 코스'), findsOneWidget);
    expect(find.text('3곳'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '시작'), findsOneWidget);
  });
}

class _FakeCourseRepository extends CourseRepository {
  _FakeCourseRepository() : super(Dio());

  @override
  Future<RouteMetrics> previewRoute(List<CourseSpot> spots) async =>
      const RouteMetrics(distanceMeters: 14826, durationSeconds: 1669);
}

class _FakeLocationUtil extends LocationUtil {
  const _FakeLocationUtil();

  @override
  Future<({double lat, double lng})> getCurrentPosition() async =>
      (lat: 36.15, lng: 127.12);
}
