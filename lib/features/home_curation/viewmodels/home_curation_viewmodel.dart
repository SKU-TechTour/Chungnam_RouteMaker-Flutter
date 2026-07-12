import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/features/home_curation/models/course.dart';
import 'package:flutterprojects/features/home_curation/viewmodels/home_curation_state.dart';

const _mockCourses = [
  Course(id: 'm1', title: '공주 감성 데이트 코스', spots: ['공산성', '중동식당', '제민천카페'], weatherTag: '맑음'),
  Course(id: 'm2', title: '부여 역사 탐방 코스', spots: ['백제문화단지', '부여국밥', '카페 백제'], weatherTag: '흐림'),
  Course(id: 'm3', title: '논산 힐링 나들이 코스', spots: ['논산딸기마을', '한정식집', '딸기카페'], weatherTag: '맑음'),
];

/// [SB 화면 1] 카드 스와이프·Plan B 셔플 상태 관리 ViewModel.
///
/// View(home_screen) → 이벤트 전달
/// Repository → 데이터 fetch
class HomeCurationViewModel extends Notifier<HomeCurationState> {
  @override
  HomeCurationState build() => const HomeCurationState();

  Future<void> loadCourses() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final courses = await ref.read(courseRepositoryProvider).fetchCourses();
      state = state.copyWith(courses: courses, isLoading: false);
    } catch (_) {
      // 백엔드 미연결 시 목업 데이터로 폴백
      state = state.copyWith(courses: _mockCourses, isLoading: false);
    }
  }

  /// Plan B: 다음 코스로 셔플
  void shuffleToNext() {
    if (state.courses.isEmpty) return;
    state = state.copyWith(
      currentIndex: (state.currentIndex + 1) % state.courses.length,
    );
  }

  void onSwipe(int index) {
    state = state.copyWith(currentIndex: index);
  }
}
