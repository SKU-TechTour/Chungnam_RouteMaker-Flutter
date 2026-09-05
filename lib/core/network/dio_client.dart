import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutterprojects/core/constants/api_constants.dart';
import 'package:flutterprojects/core/network/api_exception.dart';

/// Dio 싱글톤 래퍼 — Spring Backend와의 HTTP 통신 진입점.
///
/// Interceptor, 타임아웃, 공통 헤더는 여기서만 설정합니다.
/// Feature Repository는 [DioClient.instance]를 주입받아 사용합니다.
class DioClient {
  DioClient._();

  static final DioClient instance = DioClient._();

  late final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            // 코스 응답은 TourAPI·기상청·카카오 경로를 조합하므로 모바일망에서
            // 10초를 넘길 수 있습니다. 연결 실패는 빠르게 감지하되 정상적인 실시간
            // 조합 응답은 기다릴 수 있도록 수신 제한을 넉넉하게 둡니다.
            connectTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 45),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              if (Firebase.apps.isNotEmpty) {
                final token = await FirebaseAuth.instance.currentUser
                    ?.getIdToken();
                if (token != null && token.isNotEmpty) {
                  options.headers['Authorization'] = 'Bearer $token';
                }
              }
              handler.next(options);
            },
            onError: (error, handler) {
              final response = error.response;
              handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  response: response,
                  type: error.type,
                  error: ApiException(
                    message:
                        response?.data?.toString() ??
                        error.message ??
                        'Unknown error',
                    statusCode: response?.statusCode,
                  ),
                ),
              );
            },
          ),
        );
}
