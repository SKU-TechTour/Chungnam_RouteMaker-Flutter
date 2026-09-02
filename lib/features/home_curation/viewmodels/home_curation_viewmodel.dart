import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/constants/api_constants.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/core/network/api_exception.dart';
import 'package:flutterprojects/features/home_curation/viewmodels/home_curation_state.dart';

/// [SB 화면 1] 카드 스와이프·Plan B 셔플 상태 관리 ViewModel.
///
/// View(home_screen) → 이벤트 전달
/// Repository → 데이터 fetch
class HomeCurationViewModel extends Notifier<HomeCurationState> {
  @override
  HomeCurationState build() => const HomeCurationState();

  Future<void> loadCourses({
    String region = 'GONGJU',
    bool military = false,
    String? journeyType,
    String? routeTemplate,
    Set<String> concepts = const {},
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repository = ref.read(courseRepositoryProvider);
    if (ApiConstants.useMockData) {
      final courses = await repository.loadMockCourses(region: region);
      state = state.copyWith(
        courses: courses,
        currentIndex: 0,
        isLoading: false,
      );
      return;
    }
    // 운영 모드에서는 반드시 Spring을 거쳐 실시간 API 경로를 사용합니다.
    try {
      final courses = await repository.fetchCourses(
        region: region,
        military: military,
        journeyType: journeyType,
        routeTemplate: routeTemplate,
        concepts: concepts,
      );
      state = state.copyWith(
        courses: courses,
        currentIndex: 0,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFor(error),
      );
    }
  }

  String _messageFor(Object error) {
    if (error is ApiException) {
      if (error.statusCode == null) {
        return '백엔드 서버에 연결할 수 없습니다. Spring 서버와 API 주소를 확인해주세요.';
      }
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'Firebase 인증 설정을 확인해주세요. (${error.statusCode})';
      }
      if (error.message.contains('환경변수')) {
        return '서버의 공공 API 환경변수가 등록되지 않았습니다.';
      }
      return '실시간 코스 API 오류 (${error.statusCode}): ${error.message}';
    }
    return '실시간 관광정보를 불러오지 못했습니다: $error';
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
