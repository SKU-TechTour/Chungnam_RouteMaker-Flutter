import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/constants/api_constants.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/features/home_curation/viewmodels/home_curation_state.dart';

/// [SB 화면 1] 카드 스와이프·Plan B 셔플 상태 관리 ViewModel.
///
/// View(home_screen) → 이벤트 전달
/// Repository → 데이터 fetch
class HomeCurationViewModel extends Notifier<HomeCurationState> {
  @override
  HomeCurationState build() => const HomeCurationState();

  Future<void> loadCourses({String region = 'GONGJU'}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repository = ref.read(courseRepositoryProvider);
    if (ApiConstants.useMockData) {
      final courses = await repository.loadMockCourses(region: region);
      state = state.copyWith(courses: courses, isLoading: false);
      return;
    }
    try {
      final courses = await repository.fetchCourses(region: region);
      state = state.copyWith(courses: courses, isLoading: false);
    } catch (_) {
      final courses = await repository.loadMockCourses(region: region);
      state = state.copyWith(courses: courses, isLoading: false);
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
