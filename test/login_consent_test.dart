import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterprojects/features/auth/views/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('로그인 전 개인정보 필수 동의를 명시적으로 받는다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('개인정보 수집·이용 요약'), findsOneWidget);
    expect(find.text('[필수] 개인정보 수집·이용 동의'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(2));

    await tester.tap(find.text('Google로 계속하기'));
    await tester.pumpAndSettle();

    expect(find.text('필수 동의 항목을 확인해주세요'), findsOneWidget);
    expect(find.text('동의하고 계속'), findsOneWidget);
  });
}
