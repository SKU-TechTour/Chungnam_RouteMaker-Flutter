import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
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
            tileProvider: _MemoryTiles(),
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
    final line = tester.widget<fm.PolylineLayer>(find.byType(fm.PolylineLayer));
    expect(
      line.polylines.single.points.map((p) => p.latitude),
      route.spots.map((s) => s.latitude),
    );
    expect(
      line.polylines.single.points.map((p) => p.longitude),
      route.spots.map((s) => s.longitude),
    );
    final camera = tester
        .widget<fm.FlutterMap>(find.byType(fm.FlutterMap))
        .mapController!
        .camera;
    for (final point in line.polylines.single.points) {
      expect(camera.visibleBounds.contains(point), isTrue);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });

  testWidgets('카카오 응답 대기·실패와 지도 타일 오류에도 선택 순서의 연결선을 유지한다', (tester) async {
    final repository = _ControlledRepository();
    final route = _testRoute('first', 36.1);
    await _showMap(tester, route, repository);
    final lineBefore = tester
        .widget<fm.PolylineLayer>(find.byType(fm.PolylineLayer))
        .polylines
        .single
        .points;
    expect(lineBefore.length, 3);
    final tile = tester.widget<fm.TileLayer>(find.byType(fm.TileLayer));
    final failedTile = fm.TileImage(
      vsync: tester,
      coordinates: fm.TileCoordinates(3494, 1605, 12),
      imageProvider: MemoryImage(fm.TileProvider.transparentImage),
      onLoadComplete: (_) {},
      onLoadError: (_, _, _) {},
      tileDisplay: const fm.TileDisplay.instantaneous(),
      errorImage: null,
      cancelLoading: Completer<void>(),
    );
    tile.errorTileCallback!(failedTile, Exception('offline'), null);
    failedTile.dispose();
    await tester.pump();
    await tester.pump();
    repository.requests.single.completeError(Exception('route unavailable'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(fm.FlutterMap), findsOneWidget);
    expect(
      tester
          .widget<fm.PolylineLayer>(find.byType(fm.PolylineLayer))
          .polylines
          .single
          .points,
      lineBefore,
    );
    expect(find.byTooltip('도로 경로 재시도'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('카카오 도로 좌표를 표시하고 이전 코스의 늦은 응답은 무시한다', (tester) async {
    final repository = _ControlledRepository();
    final first = _testRoute('first', 36.1);
    final second = _testRoute('second', 36.4);
    await _showMap(tester, first, repository);
    final element = tester.element(find.byType(MapScreen));
    final container = ProviderScope.containerOf(element);
    container.read(selectedRouteProvider.notifier).state = second;
    await tester.pump();
    await tester.pump();
    expect(repository.requests.length, 2);
    final road = [
      const RoutePathPoint(latitude: 36.4, longitude: 127.1),
      const RoutePathPoint(latitude: 36.405, longitude: 127.108),
      const RoutePathPoint(latitude: 36.42, longitude: 127.12),
    ];
    repository.requests[1].complete(
      RouteMetrics(distanceMeters: 3000, durationSeconds: 400, path: road),
    );
    await tester.pump();
    repository.requests[0].complete(
      const RouteMetrics(
        distanceMeters: 1000,
        durationSeconds: 100,
        path: [
          RoutePathPoint(latitude: 36.1, longitude: 127.1),
          RoutePathPoint(latitude: 36.12, longitude: 127.12),
        ],
      ),
    );
    await tester.pump();
    final line = tester.widget<fm.PolylineLayer>(find.byType(fm.PolylineLayer));
    expect(
      line.polylines.single.points.map((p) => p.latitude),
      road.map((p) => p.latitude),
    );
    expect(find.text('카카오 도로 경로로 연결했어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _showMap(
  WidgetTester tester,
  SelectedRoute route,
  CourseRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        courseRepositoryProvider.overrideWithValue(repository),
        locationUtilProvider.overrideWithValue(const _FakeLocationUtil()),
      ],
      child: MaterialApp(
        home: MapScreen(initialRoute: route, tileProvider: _MemoryTiles()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

SelectedRoute _testRoute(String id, double latitude) => SelectedRoute(
  title: id,
  region: 'NONSAN',
  totalDistanceMeters: 1000,
  totalDurationSeconds: 100,
  spots: List.generate(
    3,
    (i) => CourseSpot(
      id: '$id-$i',
      name: '장소 $i',
      category: 'HERITAGE',
      latitude: latitude + i * .01,
      longitude: 127.1 + i * .01,
    ),
  ),
);

class _MemoryTiles extends fm.TileProvider {
  @override
  ImageProvider getImage(
    fm.TileCoordinates coordinates,
    fm.TileLayer options,
  ) => MemoryImage(fm.TileProvider.transparentImage);
}

class _ControlledRepository extends CourseRepository {
  _ControlledRepository() : super(Dio());
  final requests = <Completer<RouteMetrics>>[];
  @override
  Future<RouteMetrics> previewRoute(List<CourseSpot> spots) {
    final request = Completer<RouteMetrics>();
    requests.add(request);
    return request.future;
  }
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
