import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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

    expect(courses.length, 6);
    expect(places.length, 12);
    expect((history['receipts'] as List<dynamic>).length, 2);
    expect((history['stamps'] as List<dynamic>).length, 2);
  });
}
