import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_course.dart';

final savedCoursesProvider =
    StateNotifierProvider<SavedCoursesNotifier, List<SavedCourse>>(
      (ref) => SavedCoursesNotifier(),
    );

class SavedCoursesNotifier extends StateNotifier<List<SavedCourse>> {
  SavedCoursesNotifier()
    : super(const [
        SavedCourse(
          id: 'gongju-default',
          region: '공주',
          title: '공주 감성 하루 콤보',
          places: ['공산성', '중동식당', '제민천 카페'],
        ),
        SavedCourse(
          id: 'buyeo-default',
          region: '부여',
          title: '백제의 시간을 걷는 콤보',
          places: ['백제문화단지', '연잎밥 식당', '궁남지 로스터리'],
        ),
      ]);

  bool contains(String id) => state.any((course) => course.id == id);

  void toggle(SavedCourse course) {
    state = contains(course.id)
        ? state.where((item) => item.id != course.id).toList()
        : [...state, course];
  }

  void remove(String id) {
    state = state.where((course) => course.id != id).toList();
  }
}
