import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/constants/api_constants.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/core/network/api_exception.dart';
import 'package:flutterprojects/features/home_curation/models/course.dart';
import 'package:flutterprojects/features/home_curation/viewmodels/home_curation_state.dart';

/// [SB 화면 1] 카드 스와이프·Plan B 셔플 상태 관리 ViewModel.
///
/// View(home_screen) → 이벤트 전달
/// Repository → 데이터 fetch
class HomeCurationViewModel extends Notifier<HomeCurationState> {
  final Map<String, List<Course>> _sessionCache = {};
  final Map<String, Future<List<Course>>> _inFlight = {};
  String? _latestRequestKey;

  @override
  HomeCurationState build() => const HomeCurationState();

  Future<void> loadCourses({
    String region = 'GONGJU',
    bool military = false,
    String? journeyType,
    String? routeTemplate,
    Set<String> concepts = const {},
    bool forceRefresh = false,
  }) async {
    final cacheKey = _cacheKey(
      region: region,
      military: military,
      journeyType: journeyType,
      routeTemplate: routeTemplate,
      concepts: concepts,
    );
    _latestRequestKey = cacheKey;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearCourses: true,
    );
    final repository = ref.read(courseRepositoryProvider);
    if (ApiConstants.useMockData) {
      final courses = await repository.loadMockCourses(region: region);
      if (_latestRequestKey != cacheKey) return;
      state = state.copyWith(
        courses: courses,
        currentIndex: 0,
        isLoading: false,
      );
      return;
    }
    // 운영 모드에서는 반드시 Spring을 거쳐 실시간 API 경로를 사용합니다.
    try {
      if (forceRefresh) _sessionCache.remove(cacheKey);
      final courses =
          _sessionCache[cacheKey] ??
          await _fetchOnce(
            cacheKey,
            () => repository.fetchCourses(
              region: region,
              military: military,
              journeyType: journeyType,
              routeTemplate: routeTemplate,
              concepts: concepts,
            ),
          );
      _validateCourses(courses);
      if (_latestRequestKey != cacheKey) return;
      state = state.copyWith(
        courses: courses,
        currentIndex: 0,
        isLoading: false,
      );
    } catch (error) {
      if (_latestRequestKey != cacheKey) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFor(error),
      );
    }
  }

  /// 다른 지역으로 이동할 때 같은 공공데이터를 다시 호출하지 않도록 앱 실행
  /// 세션 동안만 미리 받아 둡니다. 디스크나 서버 DB에는 저장하지 않습니다.
  Future<bool> prefetchCourses({
    required String region,
    bool military = false,
    String? journeyType,
    String? routeTemplate,
    Set<String> concepts = const {},
  }) async {
    if (ApiConstants.useMockData) return true;
    final cacheKey = _cacheKey(
      region: region,
      military: military,
      journeyType: journeyType,
      routeTemplate: routeTemplate,
      concepts: concepts,
    );
    if (_sessionCache.containsKey(cacheKey)) return true;
    final repository = ref.read(courseRepositoryProvider);
    try {
      final courses = await _fetchOnce(
        cacheKey,
        () => repository.fetchCourses(
          region: region,
          military: military,
          journeyType: journeyType,
          routeTemplate: routeTemplate,
          concepts: concepts,
        ),
      );
      _validateCourses(courses);
      return true;
    } catch (_) {
      // 사전 로딩 실패는 현재 화면을 깨뜨리지 않습니다. 해당 지역 진입 시
      // 사용자가 재시도할 수 있도록 정상 로딩 흐름에 맡깁니다.
      return false;
    }
  }

  void _validateCourses(List<Course> courses) {
    final valid = courses.isNotEmpty &&
        courses.every(
          (course) =>
              course.spots.length >= 2 &&
              course.spots.every(
                (spot) =>
                    spot.latitude.isFinite &&
                    spot.longitude.isFinite &&
                    spot.latitude >= -90 &&
                    spot.latitude <= 90 &&
                    spot.longitude >= -180 &&
                    spot.longitude <= 180 &&
                    !(spot.latitude == 0 && spot.longitude == 0),
              ),
        );
    if (!valid) {
      throw const ApiException(message: 'Empty or invalid course response');
    }
  }

  Future<List<Course>> _fetchOnce(
    String cacheKey,
    Future<List<Course>> Function() request,
  ) {
    final running = _inFlight[cacheKey];
    if (running != null) return running;
    final future = request().then((courses) {
      _validateCourses(courses);
      _sessionCache[cacheKey] = List.unmodifiable(courses);
      return courses;
    });
    _inFlight[cacheKey] = future;
    return future.whenComplete(() => _inFlight.remove(cacheKey));
  }

  String _cacheKey({
    required String region,
    required bool military,
    required String? journeyType,
    required String? routeTemplate,
    required Set<String> concepts,
  }) {
    final sortedConcepts = concepts.toList()..sort();
    return '$region|$military|${journeyType ?? ''}|'
        '${routeTemplate ?? ''}|${sortedConcepts.join(',')}';
  }

  String _messageFor(Object error) {
    if (error is ApiException) {
      if (error.statusCode == null) {
        return '실시간 코스 서버에 연결하지 못했습니다. 네트워크 확인 후 재시도해주세요.';
      }
      if (error.statusCode == 401 || error.statusCode == 403) {
        return '로그인 인증이 만료되었습니다. 앱을 다시 실행해주세요. (${error.statusCode})';
      }
      if (error.statusCode == 503) {
        return '여행 서버가 현재 중지되어 있습니다. 서버 재시작 후 다시 시도해주세요. (503)';
      }
      if (error.message.contains('환경변수')) {
        return '서버의 공공 API 환경변수가 등록되지 않았습니다.';
      }
      return '실시간 코스를 불러오지 못했습니다. 잠시 후 다시 시도해주세요. (${error.statusCode})';
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
