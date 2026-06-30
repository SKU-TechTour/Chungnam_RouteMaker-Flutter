import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/routing/app_router.dart';
import 'package:flutterprojects/core/theme/app_theme.dart';
import 'package:flutterprojects/features/military_guide/views/countdown_widget.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

/// 앱 진입점 — 테마·라우팅·DI(ProviderScope)만 연결합니다.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TechTour',
      theme: AppTheme.light,
      routerConfig: appRouter,
      builder: (context, child) {
        return Column(
          children: [
            if (child != null) Expanded(child: child),
            const Padding(
              padding: EdgeInsets.all(8),
              child: CountdownWidget(),
            ),
          ],
        );
      },
    );
  }
}
