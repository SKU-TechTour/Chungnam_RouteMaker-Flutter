import 'package:dio/dio.dart';
import 'package:flutterprojects/core/constants/api_constants.dart';
import 'package:flutterprojects/core/network/api_exception.dart';
import 'package:flutterprojects/features/map_search/models/place.dart';

/// [SB 화면 3] 주변 장소 필터 API 호출.
class PlaceRepository {
  PlaceRepository(this._dio);

  final Dio _dio;

  Future<List<Place>> filterPlaces(PlaceFilterRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.placesFilter,
        data: request.toJson(),
      );
      final list = response.data?['places'] as List<dynamic>? ?? [];
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
