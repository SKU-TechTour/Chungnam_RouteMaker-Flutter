import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutterprojects/core/constants/api_constants.dart';
import 'package:flutterprojects/core/network/api_exception.dart';
import 'package:flutterprojects/core/network/dio_retry.dart';
import 'package:flutterprojects/features/map_search/models/place.dart';

/// [SB 화면 3] 주변 장소 필터 API 호출.
class PlaceRepository {
  PlaceRepository(this._dio);

  final Dio _dio;
  final Map<String, Future<Map<String, dynamic>?>> _accessibilityCache = {};
  final Map<String, Future<Map<String, dynamic>?>> _petInfoCache = {};

  Future<List<Place>> loadMockPlaces(PlaceFilterRequest request) async {
    final raw = await rootBundle.loadString('assets/mock/places.json');
    final list = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((item) => item['region'] == request.region)
        .map(Place.fromJson)
        .where((place) => !request.petFriendly || place.petFriendly)
        .where(
          (place) => !request.strollerAccessible || place.strollerAccessible,
        )
        .where((place) => !request.largeParking || place.largeParking)
        .toList();
    return list;
  }

  Future<List<Place>> filterPlaces(PlaceFilterRequest request) async {
    try {
      final response = await retryTransientDio(
        () => _dio.get<Map<String, dynamic>>(
          ApiConstants.places,
          queryParameters: request.toQueryParameters(),
          options: Options(extra: {'skipFirebaseAuth': true}),
        ),
      );
      final list = response.data?['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      throw ApiException(message: e.message ?? 'Failed to filter places');
    }
  }

  Future<Map<String, dynamic>?> fetchAccessibility(String contentId) async {
    final cached = _accessibilityCache[contentId];
    if (cached != null) return cached;
    final request = _fetchAccessibility(contentId);
    _accessibilityCache[contentId] = request;
    try {
      return await request;
    } catch (_) {
      if (identical(_accessibilityCache[contentId], request)) {
        _accessibilityCache.remove(contentId);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _fetchAccessibility(String contentId) async {
    final response = await retryTransientDio(
      () => _dio.get<Map<String, dynamic>>(
        '/api/external/tour/accessibility',
        queryParameters: {'contentId': contentId},
        options: Options(extra: {'skipFirebaseAuth': true}),
      ),
    );
    return response.data?['data'] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>?> fetchPetInfo(String contentId) async {
    final cached = _petInfoCache[contentId];
    if (cached != null) return cached;
    final request = _fetchPetInfo(contentId);
    _petInfoCache[contentId] = request;
    try {
      return await request;
    } catch (_) {
      if (identical(_petInfoCache[contentId], request)) {
        _petInfoCache.remove(contentId);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _fetchPetInfo(String contentId) async {
    final response = await retryTransientDio(
      () => _dio.get<Map<String, dynamic>>(
        '/api/external/tour/pet-info',
        queryParameters: {'contentId': contentId},
        options: Options(extra: {'skipFirebaseAuth': true}),
      ),
    );
    return response.data?['data'] as Map<String, dynamic>?;
  }
}
