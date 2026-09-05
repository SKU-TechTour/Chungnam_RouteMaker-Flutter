import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutterprojects/core/network/api_exception.dart';
import 'package:flutterprojects/features/home_curation/models/course.dart';
import 'package:flutterprojects/features/home_curation/models/selected_route.dart';

/// [SB 화면 1] 코스 큐레이션 API 호출.
///
/// ViewModel은 이 클래스만 알고, Dio/URL 세부사항은 모릅니다.
class CourseRepository {
  CourseRepository(this._dio);

  final Dio _dio;

  Future<List<Course>> loadMockCourses({required String region}) async {
    final raw = await rootBundle.loadString('assets/mock/courses.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .where((item) => (item as Map<String, dynamic>)['region'] == region)
        .map((item) => Course.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Course>> fetchCourses({
    required String region,
    bool military = false,
    String? journeyType,
    String? routeTemplate,
    Set<String> concepts = const {},
    int variant = 0,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/courses/recommendations',
        data: {
          'region': region,
          'military': military,
          'journeyType': journeyType,
          'routeTemplate': routeTemplate,
          'concepts': concepts.toList(),
          'variant': variant,
        },
      );
      final data = response.data?['data'] as List<dynamic>?;
      if (data == null) {
        throw const ApiException(message: 'Invalid course list response');
      }
      return data
          .map((item) => Course.fromJson(item as Map<String, dynamic>))
          .toList();
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

  Future<Map<String, dynamic>?> fetchSpotDetails(String contentId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/external/tour/common-info',
        queryParameters: {'contentId': contentId},
      );
      return response.data?['data'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      throw ApiException(message: e.message ?? 'Failed to fetch place details');
    }
  }

  Future<RouteMetrics> previewRoute(List<CourseSpot> spots) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/courses/route-preview',
        data: {
          'spots': spots
              .map(
                (spot) => {
                  'id': int.tryParse(spot.id) ?? -1,
                  'latitude': spot.latitude,
                  'longitude': spot.longitude,
                },
              )
              .toList(),
        },
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ApiException(message: 'Invalid route preview response');
      }
      final routes = data['routes'] as List<dynamic>? ?? const [];
      final path = routes
          .expand(
            (route) =>
                ((route as Map<String, dynamic>)['path'] as List<dynamic>? ??
                const []),
          )
          .whereType<Map<String, dynamic>>()
          .map(RoutePathPoint.fromJson)
          .toList();
      final guides = routes
          .expand(
            (route) =>
                ((route as Map<String, dynamic>)['guides'] as List<dynamic>? ??
                const []),
          )
          .whereType<Map<String, dynamic>>()
          .map(RouteGuideStep.fromJson)
          .toList();
      return RouteMetrics(
        distanceMeters: (data['totalDistanceMeters'] as num?)?.round() ?? 0,
        durationSeconds: (data['totalDurationSeconds'] as num?)?.round() ?? 0,
        path: path,
        guides: guides,
      );
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      throw ApiException(message: e.message ?? 'Failed to preview route');
    }
  }
}
