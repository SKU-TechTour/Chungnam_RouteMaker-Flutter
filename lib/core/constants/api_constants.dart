/// Spring Backend REST API 엔드포인트 상수.
///
/// [baseUrl]은 환경(dev/staging/prod)별로 분리할 예정이면
/// `--dart-define` 또는 flavor 설정으로 교체하세요.
abstract final class ApiConstants {
  /// 공모전 제출 앱은 한국관광공사 OpenAPI를 실시간 호출합니다.
  /// Mock은 UI 개발/자동 테스트에서 명시적으로 켠 경우에만 사용합니다.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );

  /// Release/스토어 빌드는 별도 인자를 빠뜨려도 운영 서버에 연결합니다.
  /// 로컬 서버로 디버깅할 때만 `--dart-define=API_BASE_URL=http://...`로
  /// 덮어씁니다. Android 실기기는 adb reverse 후 localhost를 사용할 수 있습니다.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://port-0-chungnam-routemaker-spring-mtnrcg3t5c416fce.sel3.cloudtype.app',
  );

  // home_curation
  static const String courseRecommend = '/api/courses/recommend';

  // military_guide
  static const String militarySafeTime = '/api/military/safe-time';

  // map_search
  static const String places = '/api/places';
}
