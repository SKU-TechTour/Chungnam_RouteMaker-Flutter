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

  Future<List<Course>> fetchCourses({
    required String region,
    bool military = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.courseRecommend,
        data: {'region': region, 'military': military},
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid course response');
      }
      return [Course.fromJson(data)];
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      throw ApiException(message: e.message ?? 'Failed to fetch courses');
    }
  }

  Future<Course> shufflePlanB(String courseId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/courses/$courseId/shuffle',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid course response');
      }
      return Course.fromJson(data);
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      throw ApiException(message: e.message ?? 'Failed to shuffle course');
    }
  }
}
