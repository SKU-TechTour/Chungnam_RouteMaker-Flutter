import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterprojects/features/home_curation/models/course.dart';
import 'package:flutterprojects/features/home_curation/repositories/course_repository.dart';

const _spots = [
  CourseSpot(
    id: '1',
    name: 'A',
    category: 'CAFE',
    latitude: 36.1,
    longitude: 127.1,
  ),
  CourseSpot(
    id: '2',
    name: 'B',
    category: 'CAFE',
    latitude: 36.2,
    longitude: 127.2,
  ),
  CourseSpot(
    id: '3',
    name: 'C',
    category: 'CAFE',
    latitude: 36.3,
    longitude: 127.3,
  ),
];

void main() {
  test('장소 상세정보는 같은 세션에서 한 번만 요청한다', () async {
    var requestCount = 0;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestCount++;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'data': {'overview': '상세 소개'},
                },
              ),
            );
          },
        ),
      );
    final repository = CourseRepository(dio);

    final first = await repository.fetchSpotDetails('123');
    final second = await repository.fetchSpotDetails('123');

    expect(first?['overview'], '상세 소개');
    expect(second?['overview'], '상세 소개');
    expect(requestCount, 1);
    dio.close();
  });

  test('일부 구간 누락·응답 순서 변경에도 A→B→C를 모두 연결한다', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect((options.data['spots'] as List).map((s) => s['id']), [
              1,
              2,
              3,
            ]);
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'data': {
                    'routes': [
                      {
                        'originPlaceId': 2,
                        'destinationPlaceId': 3,
                        'path': [
                          {'latitude': 36.21, 'longitude': 127.21},
                          {'latitude': 36.29, 'longitude': 127.29},
                        ],
                      },
                      {
                        'originPlaceId': 1,
                        'destinationPlaceId': 2,
                        'path': null,
                      },
                    ],
                  },
                },
              ),
            );
          },
        ),
      );
    final metrics = await CourseRepository(dio).previewRoute(_spots);
    expect(metrics.path.map((p) => p.latitude), [
      36.1,
      36.2,
      36.2,
      36.21,
      36.29,
      36.3,
    ]);
    expect(metrics.usesStraightConnections, isTrue);
    dio.close();
  });

  test('모든 카카오 구간이 있으면 도로 좌표와 실제 장소 좌표를 연결한다', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': {
                  'routes': List.generate(
                    2,
                    (i) => {
                      'originPlaceId': i + 1,
                      'destinationPlaceId': i + 2,
                      'path': [
                        {
                          'latitude': _spots[i].latitude,
                          'longitude': _spots[i].longitude,
                        },
                        {
                          'latitude': _spots[i + 1].latitude,
                          'longitude': _spots[i + 1].longitude,
                        },
                      ],
                    },
                  ),
                },
              },
            ),
          ),
        ),
      );
    final metrics = await CourseRepository(dio).previewRoute(_spots);
    expect(metrics.path.first.latitude, 36.1);
    expect(metrics.path.last.latitude, 36.3);
    expect(metrics.path.any((p) => p.latitude == 36.2), isTrue);
    expect(metrics.usesStraightConnections, isFalse);
    dio.close();
  });
}
