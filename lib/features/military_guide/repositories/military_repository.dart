import 'package:dio/dio.dart';
import 'package:flutterprojects/core/constants/api_constants.dart';
import 'package:flutterprojects/core/network/api_exception.dart';
import 'package:flutterprojects/features/military_guide/data/platform/live_widget_channel.dart';

/// [SB 화면 2] 훈련소 가이드 API + 라이브 위젯 채널 조합.
class MilitaryRepository {
  MilitaryRepository({
    required Dio dio,
    required LiveWidgetChannel liveWidgetChannel,
  })  : _dio = dio,
        _liveWidgetChannel = liveWidgetChannel;

  final Dio _dio;
  final LiveWidgetChannel _liveWidgetChannel;

  /// Spring `GET /api/military/safe-time` — 복귀 가능까지 남은 분
  Future<int> fetchSafeTimeMinutes() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiConstants.militarySafeTime);
      return response.data?['minutesLeft'] as int? ?? 0;
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
