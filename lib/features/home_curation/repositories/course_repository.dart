import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutterprojects/core/network/api_exception.dart';
import 'package:flutterprojects/core/network/dio_retry.dart';
import 'package:flutterprojects/features/home_curation/models/course.dart';
import 'package:flutterprojects/features/home_curation/models/selected_route.dart';

/// [SB 화면 1] 코스 큐레이션 API 호출.
///
/// ViewModel은 이 클래스만 알고, Dio/URL 세부사항은 모릅니다.
class CourseRepository {
  CourseRepository(this._dio);

  final Dio _dio;
  final Map<String, Future<Map<String, dynamic>?>> _spotDetailCache = {};

  Future<bool> isServerHealthy() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/actuator/health',
        options: Options(
          extra: {'skipFirebaseAuth': true},
          receiveTimeout: const Duration(seconds: 7),
        ),
      );
      return response.statusCode == 200 && response.data?['status'] == 'UP';
    } on DioException {
      return false;
    }
  }

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
    final requestData = {
      'region': region,
      'military': military,
      'journeyType': journeyType,
      'routeTemplate': routeTemplate,
      'concepts': concepts.toList(),
      'variant': variant,
    };
    try {
      var courses = await _fetchCoursesOnce(requestData);
      // 간헐적으로 코스 응답은 성공하지만 기상청 배열만 비어 오는 경우가 있다.
      // 빈 예보를 '비가 오지 않음'으로 오인하지 않고 한 번만 다시 요청한다.
      if (courses.isNotEmpty &&
          courses.every((course) => course.hourlyWeather.isEmpty)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        try {
          final retried = await _fetchCoursesOnce(requestData);
          if (retried.any((course) => course.hourlyWeather.isNotEmpty)) {
            courses = retried;
          }
        } catch (_) {
          // 관광 코스 자체는 유효하므로 날씨 재시도 실패가 전체 화면을 막지 않는다.
        }
      }
      return courses;
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      throw ApiException(message: e.message ?? 'Failed to fetch courses');
    }
  }

  Future<List<Course>> _fetchCoursesOnce(
    Map<String, dynamic> requestData,
  ) async {
    try {
      final response = await retryTransientDio(
        () => _dio.post<Map<String, dynamic>>(
          '/api/courses/recommendations',
          data: requestData,
          options: Options(extra: {'skipFirebaseAuth': true}),
        ),
      );
      final data = response.data?['data'] as List<dynamic>?;
      if (data == null) {
        throw const ApiException(message: 'Invalid course list response');
      }
      return data
          .map((item) => Course.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      // 이전 서버 버전은 목록 경로만 인증 대상으로 설정되어 있었습니다.
      if (error.response?.statusCode != 401 &&
          error.response?.statusCode != 403) {
        rethrow;
      }
      final fallback = await retryTransientDio(
        () => _dio.post<Map<String, dynamic>>(
          '/api/courses/recommend',
          data: requestData,
          options: Options(extra: {'skipFirebaseAuth': true}),
        ),
      );
      final fallbackData = fallback.data?['data'];
      if (fallbackData is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid course response');
      }
      return [Course.fromJson(fallbackData)];
    }
  }

  Future<Course> shufflePlanB(String courseId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/courses/$courseId/shuffle',
        options: Options(extra: {'skipFirebaseAuth': true}),
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
    final cached = _spotDetailCache[contentId];
    if (cached != null) return cached;

    final request = _fetchSpotDetailsFromNetwork(contentId);
    _spotDetailCache[contentId] = request;
    try {
      return await request;
    } catch (_) {
      if (identical(_spotDetailCache[contentId], request)) {
        _spotDetailCache.remove(contentId);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _fetchSpotDetailsFromNetwork(
    String contentId,
  ) async {
    try {
      final response = await retryTransientDio(
        () => _dio.get<Map<String, dynamic>>(
          '/api/external/tour/common-info',
          queryParameters: {'contentId': contentId},
        ),
      );
      return response.data?['data'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      throw ApiException(message: e.message ?? 'Failed to fetch place details');
    }
  }

  /// 현재 선택된 코스의 상세정보만 세션 메모리에 미리 준비합니다.
  /// 디스크나 서버 DB에는 저장하지 않으며 실패한 요청은 캐시에서 제거됩니다.
  void prefetchSpotDetails(Iterable<CourseSpot> spots) {
    for (final spot in spots.where(
      (spot) => spot.source == 'TOUR_API_REALTIME',
    )) {
      unawaited(fetchSpotDetails(spot.id).catchError((_) => null));
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
        options: Options(extra: {'skipFirebaseAuth': true}),
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ApiException(message: 'Invalid route preview response');
      }
      final routes = data['routes'] as List<dynamic>? ?? const [];
      final path = <RoutePathPoint>[];
      var usesStraightConnections = false;
      // Match each response leg to the selected pair. Flattening only successful
      // legs can silently omit a stop or join unrelated roads.
      for (var index = 0; index + 1 < spots.length; index++) {
        final origin = spots[index];
        final destination = spots[index + 1];
        final matchingLegs = routes.whereType<Map<String, dynamic>>().where(
          (leg) =>
              leg['originPlaceId']?.toString() == origin.id &&
              leg['destinationPlaceId']?.toString() == destination.id,
        );
        final leg = matchingLegs.isEmpty ? null : matchingLegs.first;
        final coordinates = (leg?['path'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .where(
              (point) => point['latitude'] is num && point['longitude'] is num,
            )
            .map(RoutePathPoint.fromJson)
            .where(
              (p) =>
                  p.latitude.isFinite &&
                  p.longitude.isFinite &&
                  p.latitude.abs() <= 90 &&
                  p.longitude.abs() <= 180 &&
                  !(p.latitude == 0 && p.longitude == 0),
            )
            .toList();
        path.add(
          RoutePathPoint(
            latitude: origin.latitude,
            longitude: origin.longitude,
          ),
        );
        if (coordinates.length >= 2) {
          path.addAll(coordinates);
        } else {
          usesStraightConnections = true;
        }
        path.add(
          RoutePathPoint(
            latitude: destination.latitude,
            longitude: destination.longitude,
          ),
        );
      }
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
        usesStraightConnections: usesStraightConnections,
      );
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      throw ApiException(message: e.message ?? 'Failed to preview route');
    }
  }
}
