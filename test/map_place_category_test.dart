import 'package:flutter_test/flutter_test.dart';
import 'package:flutterprojects/features/home_curation/models/course.dart';
import 'package:flutterprojects/features/map_search/models/place.dart';

void main() {
  test('코스 장소의 식당·유적지·카페·훈련소 종류를 구분한다', () {
    Place place(String id, String name, String category) =>
        Place.fromCourseSpot(
          CourseSpot(
            id: id,
            name: name,
            category: category,
            latitude: 36.1,
            longitude: 127.1,
          ),
        );

    expect(place('10', '식당', 'RESTAURANT').type, PlaceType.restaurant);
    expect(place('11', '유적지', 'HERITAGE').type, PlaceType.tourist);
    expect(place('12', '카페', 'CAFE').type, PlaceType.cafe);
    expect(place('-1', '육군훈련소', 'HERITAGE').type, PlaceType.trainingCenter);
  });
}
