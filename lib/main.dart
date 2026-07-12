import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/platform/kakao_init.dart';
import 'package:flutterprojects/core/routing/app_router.dart';
import 'package:flutterprojects/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initKakaoMap();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '충남 루트메이커',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
