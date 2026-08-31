import 'package:dio/dio.dart';
import 'package:flutterprojects/core/constants/api_constants.dart';
import 'package:flutterprojects/core/network/api_exception.dart';
import 'package:flutterprojects/features/military_guide/data/platform/live_widget_channel.dart';

/// [SB 화면 2] 훈련소 가이드 API + 라이브 위젯 채널 조합.
class MilitaryRepository {
  factory MilitaryRepository({
    required Dio dio,
    required LiveWidgetChannel liveWidgetChannel,
  }) => MilitaryRepository._(dio, liveWidgetChannel);

  MilitaryRepository._(this._dio, this._liveWidgetChannel);

  final Dio _dio;
  final LiveWidgetChannel _liveWidgetChannel;

  /// Spring `GET /api/military/safe-time` — 복귀 가능까지 남은 분
  Future<int> fetchSafeTimeMinutes({
    required int unitId,
    required double lat,
    required double lng,
    required int returnDeadlineMinutes,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.militarySafeTime,
        queryParameters: {
          'unitId': unitId,
          'lat': lat,
          'lng': lng,
          'returnDeadlineMinutes': returnDeadlineMinutes,
        },
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic> || data['remainingMinutes'] is! int) {
        throw const ApiException(message: 'Invalid safe-time response');
      }
      return data['remainingMinutes'] as int;
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      throw ApiException(message: e.message ?? 'Failed to fetch safe time');
    }
  }

  Future<void> syncLiveWidget(int secondsLeft) {
    return _liveWidgetChannel.updateCountdown(secondsLeft);
  }
}
