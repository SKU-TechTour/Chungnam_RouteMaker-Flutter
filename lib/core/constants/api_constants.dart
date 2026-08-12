/// Spring Backend REST API 엔드포인트 상수.
///
/// [baseUrl]은 환경(dev/staging/prod)별로 분리할 예정이면
/// `--dart-define` 또는 flavor 설정으로 교체하세요.
abstract final class ApiConstants {
  /// Override this with `--dart-define=API_BASE_URL=http://...` for a device.
  /// Android emulators reach the development machine through 10.0.2.2.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  // home_curation
  static const String courseRecommend = '/api/courses/recommend';

  // military_guide
  static const String militarySafeTime = '/api/military/safe-time';

  // map_search
  static const String places = '/api/places';
}
