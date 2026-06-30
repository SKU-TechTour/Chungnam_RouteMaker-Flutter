import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterprojects/main.dart';

void main() {
  testWidgets('앱이 정상적으로 빌드된다', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();

    expect(find.text('홈 큐레이션'), findsOneWidget);
  });
}
