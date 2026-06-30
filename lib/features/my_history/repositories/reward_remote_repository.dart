import 'package:dio/dio.dart';
import 'package:flutterprojects/core/constants/api_constants.dart';
import 'package:flutterprojects/core/network/api_exception.dart';
import 'package:flutterprojects/features/my_history/models/receipt.dart';

/// [SB 화면 4] Spring `GET /api/rewards` — 서버 리워드/영수증 데이터.
class RewardRemoteRepository {
  RewardRemoteRepository(this._dio);

  final Dio _dio;

  Future<List<Receipt>> fetchRewards() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiConstants.rewards);
      final list = response.data?['receipts'] as List<dynamic>? ?? [];
      return list
          .map((e) => Receipt.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      throw ApiException(message: e.message ?? 'Failed to fetch rewards');
    }
  }
}
