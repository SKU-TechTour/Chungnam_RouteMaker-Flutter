/// 3단 콤보 코스 데이터 모델.
///
/// Spring `GET /api/courses` 응답 JSON과 1:1 매핑합니다.
class Course {
  const Course({
    required this.id,
    required this.title,
    required this.spots,
    this.weatherTag,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      spots: (json['spots'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      weatherTag: json['weatherTag'] as String?,
    );
  }

  final String id;
  final String title;
  final List<String> spots;
  final String? weatherTag;
}
