import 'package:dio/dio.dart';
import 'package:flutterprojects/core/constants/api_constants.dart';
import 'package:flutterprojects/core/network/api_exception.dart';
import 'package:flutterprojects/features/home_curation/models/course.dart';

/// [SB 화면 1] 코스 큐레이션 API 호출.
///
/// ViewModel은 이 클래스만 알고, Dio/URL 세부사항은 모릅니다.
class CourseRepository {
  CourseRepository(this._dio);

  final Dio _dio;

  Future<List<Course>> fetchCourses() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiConstants.courses);
      final list = response.data?['courses'] as List<dynamic>? ?? [];
      return list
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      throw ApiException(message: e.message ?? 'Failed to fetch courses');
    }
  }
}
