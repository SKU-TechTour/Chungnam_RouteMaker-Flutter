import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutterprojects/core/constants/api_constants.dart';
import 'package:flutterprojects/core/network/api_exception.dart';
import 'package:flutterprojects/features/map_search/models/place.dart';

/// [SB 화면 3] 주변 장소 필터 API 호출.
class PlaceRepository {
  PlaceRepository(this._dio);

  final Dio _dio;

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
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.places,
        queryParameters: request.toQueryParameters(),
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
}
