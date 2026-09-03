import 'package:flutter_test/flutter_test.dart';
import 'package:flutterprojects/features/home_curation/models/course.dart';
import 'package:flutterprojects/features/home_curation/models/selected_route.dart';
import 'package:flutterprojects/features/map_search/viewmodels/journey_progress_provider.dart';
import 'package:flutterprojects/features/my_history/repositories/stamp_local_repository.dart';
import 'package:flutterprojects/features/saved/models/saved_course.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const spots = [
    CourseSpot(
      id: 'food-1',
      name: '점심 식당',
      category: 'FOOD',
      latitude: 36.1,
      longitude: 127.1,
    ),
    CourseSpot(
      id: 'training-center',
      name: '논산훈련소',
      category: 'MILITARY',
      latitude: 36.12,
      longitude: 127.11,
    ),
  ];
  const route = SelectedRoute(
    title: '입영일 코스',
    region: 'NONSAN',
    spots: spots,
    totalDistanceMeters: 4200,
    totalDurationSeconds: 900,
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('마지막 경유지를 완료한 뒤에만 영수증과 스탬프를 저장한다', () async {
    final repository = StampLocalRepository();
    final notifier = JourneyProgressNotifier(repository)..start(route);

    expect(await notifier.completeCurrentStop(), isFalse);
    expect(await repository.loadReceipts(), isEmpty);
    expect(await repository.loadStamps(), isEmpty);

    expect(await notifier.completeCurrentStop(), isTrue);
    expect((await repository.loadReceipts()).single.places, ['점심 식당', '논산훈련소']);
    expect((await repository.loadStamps()).single.region, 'NONSAN');
  });

  test('찜 코스는 편집된 전체 경로를 직렬화한다', () {
    const saved = SavedCourse(
      id: 'NONSAN-type-a-0',
      region: '논산',
      regionCode: 'NONSAN',
      title: '입영일 코스',
      spots: spots,
      totalDistanceMeters: 4200,
      totalDurationSeconds: 900,
    );

    final restored = SavedCourse.fromJson(saved.toJson());

    expect(restored.hasSameRoute(saved), isTrue);
    expect(restored.toSelectedRoute().spots.map((spot) => spot.name), [
      '점심 식당',
      '논산훈련소',
    ]);
  });
}
