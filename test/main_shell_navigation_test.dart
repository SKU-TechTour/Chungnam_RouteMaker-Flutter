import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterprojects/features/home_curation/views/main_shell.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('탭 화면 전환 중 연속 터치에도 Shell 레이아웃이 유지된다', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const Scaffold(body: Text('홈 화면')),
            ),
            GoRoute(
              path: '/map',
              builder: (_, _) => const Scaffold(body: Text('지도 화면')),
            ),
            GoRoute(
              path: '/saved',
              builder: (_, _) => const Scaffold(body: Text('찜 화면')),
            ),
            GoRoute(
              path: '/history',
              builder: (_, _) => const Scaffold(body: Text('내 정보 화면')),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();

    await tester.tap(find.text('주변 코스'));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.text('홈'));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.text('찜'));
    await tester.pumpAndSettle();

    expect(find.text('찜 화면'), findsOneWidget);
    expect(tester.takeException(), isNull);
    router.dispose();
  });
}
