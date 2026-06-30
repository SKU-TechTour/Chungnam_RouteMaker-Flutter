import 'package:flutter/services.dart';

/// Android/iOS 네이티브 라이브 위젯과 통신하는 MethodChannel.
///
/// View가 아닌 platform/data 레이어에 위치합니다.
/// [MilitaryRepository]가 API + 채널을 조합합니다.
class LiveWidgetChannel {
  LiveWidgetChannel({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.techtour/live_widget');

  final MethodChannel _channel;

  Future<void> updateCountdown(int secondsLeft) async {
    await _channel.invokeMethod<void>('updateCountdown', {
      'secondsLeft': secondsLeft,
    });
  }

  Future<int?> getNativeCountdown() async {
    final result = await _channel.invokeMethod<int>('getCountdown');
    return result;
  }
}
