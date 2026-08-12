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
    final combo = json['combo'] as List<dynamic>? ?? const [];
    return Course(
      id: json['id'].toString(),
      title: json['title'] as String,
      spots: combo
          .map((e) => (e as Map<String, dynamic>)['name'] as String)
          .toList(),
      weatherTag: json['indoor'] == true ? 'Indoor' : 'Outdoor',
    );
  }

  final String id;
  final String title;
  final List<String> spots;
  final String? weatherTag;
}
