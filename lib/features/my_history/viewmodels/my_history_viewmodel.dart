import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/features/my_history/viewmodels/my_history_state.dart';

/// [SB 화면 4] 원터치 공유·스탬프 개수 ViewModel.
class MyHistoryViewModel extends Notifier<MyHistoryState> {
  @override
  MyHistoryState build() => const MyHistoryState();

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final receipts =
          await ref.read(rewardRemoteRepositoryProvider).fetchRewards();
      final stamps = await ref.read(stampLocalRepositoryProvider).loadStamps();
      state = state.copyWith(
        receipts: receipts,
        stamps: stamps,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// 원터치 공유 — share_plus 패키지 연동 지점
  Future<void> shareReceipt(String receiptId) async {
    state = state.copyWith(isSharing: true);
    // TODO: share_plus로 영수증 이미지/텍스트 공유
    await Future<void>.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(isSharing: false);
  }
}
