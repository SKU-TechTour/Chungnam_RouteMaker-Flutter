/// 3단 콤보 코스 데이터 모델.
///
/// Spring `GET /api/courses` 응답 JSON과 1:1 매핑합니다.
class Course {
  const Course({
    required this.id,
    required this.title,
    required this.spots,
    this.weatherTag,
    this.totalDistanceMeters = 0,
    this.totalDurationSeconds = 0,
    this.source,
    this.hourlyWeather = const [],
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    final combo = json['combo'] as List<dynamic>? ?? const [];
    return Course(
      id: json['id'].toString(),
      title: json['title'] as String,
      spots: combo
          .map((e) => CourseSpot.fromJson(e as Map<String, dynamic>))
          .toList(),
      weatherTag:
          json['weather'] as String? ??
          (json['indoor'] == true ? 'RAINY' : 'CLEAR'),
      totalDistanceMeters: json['totalDistanceMeters'] as int? ?? 0,
      totalDurationSeconds: json['totalDurationSeconds'] as int? ?? 0,
      source: json['source'] as String?,
      hourlyWeather: (json['hourlyWeather'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HourlyWeather.fromJson)
          .toList(),
    );
  }

  final String id;
  final String title;
  final List<CourseSpot> spots;
  final String? weatherTag;
  final int totalDistanceMeters;
  final int totalDurationSeconds;
  final String? source;
  final List<HourlyWeather> hourlyWeather;

  String get formattedDuration {
    if (totalDurationSeconds <= 0) return '시간 계산 중';
    final minutes = (totalDurationSeconds / 60).round();
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return hours > 0 ? '약 $hours시간 $remaining분' : '약 $remaining분';
  }
}

class HourlyWeather {
  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.precipitationExpected,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) => HourlyWeather(
    time: json['time'] as String? ?? '--:--',
    temperature: (json['temperature'] as num?)?.round() ?? 0,
    precipitationProbability:
        (json['precipitationProbability'] as num?)?.round() ?? 0,
    precipitationExpected: json['precipitationExpected'] as bool? ?? false,
  );

  final String time;
  final int temperature;
  final int precipitationProbability;
  final bool precipitationExpected;
}

class CourseSpot {
  const CourseSpot({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.source,
    this.address,
  });

  factory CourseSpot.fromJson(Map<String, dynamic> json) => CourseSpot(
    id: json['id'].toString(),
    name: json['name'] as String,
    category: json['category'] as String? ?? 'HERITAGE',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    imageUrl: json['imageUrl'] as String?,
    source: json['source'] as String?,
    address: json['address'] as String?,
  );

  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? source;
  final String? address;
}
