import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterprojects/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('앱이 정상적으로 빌드된다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': false});
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();

    expect(find.text('충남 루트메이커'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('건너뛰기'), findsOneWidget);
  });
}
