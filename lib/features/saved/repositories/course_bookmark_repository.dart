import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/saved_course.dart';

class CourseBookmarkRepository {
  CourseBookmarkRepository(this._dio);

  final Dio _dio;

  bool get canWrite =>
      Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;

  Future<void> save(SavedCourse course) async {
    if (!canWrite) return;
    await _dio.post<void>(
      '/api/courses/bookmarks',
      data: course.toBookmarkRequest(),
    );
  }

  Future<void> remove(SavedCourse course) async {
    if (!canWrite) return;
    await _dio.delete<void>(
      '/api/courses/bookmarks/${Uri.encodeComponent(course.routeKey)}',
    );
  }

  Future<List<SavedCourse>> fetchPopular({int limit = 3}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/courses/popular',
      queryParameters: {'limit': limit},
      options: Options(extra: {'skipFirebaseAuth': true}),
    );
    final data = response.data?['data'];
    if (data is! List<dynamic>) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(SavedCourse.fromPopularApi)
        .toList(growable: false);
  }
}
