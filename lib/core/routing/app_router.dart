import 'package:go_router/go_router.dart';
import 'package:flutterprojects/features/home_curation/views/home_screen.dart';
import 'package:flutterprojects/features/map_search/views/map_screen.dart';
import 'package:flutterprojects/features/my_history/views/receipt_share_screen.dart';
import 'package:flutterprojects/features/my_history/views/stamp_history_screen.dart';

/// SB 화면별 라우트 정의.
///
/// ShellRoute/BottomNavigationBar가 필요하면 여기서 확장합니다.
abstract final class AppRoutes {
  static const home = '/';
  static const map = '/map';
  static const receiptShare = '/history/receipt';
  static const stampHistory = '/history/stamps';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.map,
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: AppRoutes.receiptShare,
      builder: (context, state) => const ReceiptShareScreen(),
    ),
    GoRoute(
      path: AppRoutes.stampHistory,
      builder: (context, state) => const StampHistoryScreen(),
    ),
  ],
);
