import 'package:dio/dio.dart';

/// 모바일 네트워크 전환이나 Cloudtype의 짧은 기동 지연처럼 일시적인 오류만
/// 한 번 재시도합니다. 인증/요청 형식 오류는 재시도하지 않습니다.
Future<T> retryTransientDio<T>(Future<T> Function() request) async {
  for (var attempt = 0; attempt < 2; attempt++) {
    try {
      return await request();
    } on DioException catch (error) {
      if (attempt == 1 || !_isTransient(error)) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
  }
  throw StateError('unreachable');
}

bool _isTransient(DioException error) {
  final statusCode = error.response?.statusCode;
  if (statusCode == 408 || statusCode == 429) return true;
  if (statusCode != null && statusCode >= 500) return true;
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError ||
    DioExceptionType.unknown => true,
    _ => false,
  };
}
