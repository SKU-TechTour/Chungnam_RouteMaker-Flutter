import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterprojects/features/home_curation/models/course.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Day 2 Mock JSON 세 종류를 정상 파싱한다', () async {
    final courses =
        jsonDecode(await rootBundle.loadString('assets/mock/courses.json'))
            as List<dynamic>;
    final places =
        jsonDecode(await rootBundle.loadString('assets/mock/places.json'))
            as List<dynamic>;
    final history =
        jsonDecode(await rootBundle.loadString('assets/mock/history.json'))
            as Map<String, dynamic>;

    expect(courses.length, 15);
    expect(places.length, 12);
    expect((history['receipts'] as List<dynamic>).length, 2);
    expect((history['stamps'] as List<dynamic>).length, 2);

    final parsedCourses = courses
        .whereType<Map<String, dynamic>>()
        .map(Course.fromJson)
        .toList();
    expect(
      parsedCourses.every(
        (course) =>
            course.spots.length == 3 &&
            course.spots.every(
              (spot) => spot.latitude != 0 && spot.longitude != 0,
            ),
      ),
      isTrue,
    );
    for (final region in ['NONSAN', 'GONGJU', 'BUYEO']) {
      expect(courses.where((course) => course['region'] == region).length, 5);
    }
  });
}
