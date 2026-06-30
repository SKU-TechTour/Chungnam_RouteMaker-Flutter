import 'package:dio/dio.dart';
import 'package:flutterprojects/core/constants/api_constants.dart';
import 'package:flutterprojects/core/network/api_exception.dart';

/// Dio 싱글톤 래퍼 — Spring Backend와의 HTTP 통신 진입점.
///
/// Interceptor, 타임아웃, 공통 헤더는 여기서만 설정합니다.
/// Feature Repository는 [DioClient.instance]를 주입받아 사용합니다.
class DioClient {
  DioClient._();

  static final DioClient instance = DioClient._();

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final response = error.response;
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: response,
              type: error.type,
              error: ApiException(
                message: response?.data?.toString() ?? error.message ?? 'Unknown error',
                statusCode: response?.statusCode,
              ),
            ),
          );
        },
      ),
    );
}
