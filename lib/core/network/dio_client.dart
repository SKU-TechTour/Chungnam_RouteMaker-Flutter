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
              if (options.extra['skipFirebaseAuth'] == true) {
                handler.next(options);
                return;
              }
              try {
                if (Firebase.apps.isNotEmpty) {
                  final token = await FirebaseAuth.instance.currentUser
                      ?.getIdToken();
                  if (token != null && token.isNotEmpty) {
                    options.headers['Authorization'] = 'Bearer $token';
                  }
                }
              } on FirebaseAuthException {
                // 공개 조회 API는 토큰 갱신 장애가 있어도 호출할 수 있게 진행합니다.
                // 인증이 필요한 API의 401은 onError에서 새 토큰으로 한 번 재시도합니다.
              }
              handler.next(options);
            },
            onError: (error, handler) async {
              if (error.response?.statusCode == 401 &&
                  error.requestOptions.extra['skipFirebaseAuth'] != true &&
                  error.requestOptions.extra['firebaseAuthRetried'] != true &&
                  Firebase.apps.isNotEmpty &&
                  FirebaseAuth.instance.currentUser != null) {
                try {
                  final token = await FirebaseAuth.instance.currentUser!
                      .getIdToken(true);
                  if (token != null && token.isNotEmpty) {
                    final options = error.requestOptions;
                    options.extra['firebaseAuthRetried'] = true;
                    options.headers['Authorization'] = 'Bearer $token';
                    final response = await DioClient.instance.dio.fetch(
                      options,
                    );
                    handler.resolve(response);
                    return;
                  }
                } on FirebaseAuthException {
                  // 아래 공통 ApiException 변환으로 이어집니다.
                } on DioException {
                  // 재시도도 실패한 경우 최초 401을 일관된 오류로 전달합니다.
                }
              }
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
