/// Spring Backend REST API 엔드포인트 상수.
///
/// [baseUrl]은 환경(dev/staging/prod)별로 분리할 예정이면
/// `--dart-define` 또는 flavor 설정으로 교체하세요.
abstract final class ApiConstants {
  static const String baseUrl = 'http://localhost:8080';

  // home_curation
  static const String courses = '/api/courses';

  // military_guide
  static const String militarySafeTime = '/api/military/safe-time';

  // map_search
  static const String placesFilter = '/api/places/filter';

  // my_history
  static const String rewards = '/api/rewards';
}
