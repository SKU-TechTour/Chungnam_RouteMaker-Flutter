import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/features/my_history/viewmodels/my_history_state.dart';

class MyHistoryViewModel extends Notifier<MyHistoryState> {
  @override
  MyHistoryState build() => const MyHistoryState();

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(stampLocalRepositoryProvider);
      final receipts = await repository.loadReceipts();
      final localStamps = await repository.loadStamps();
      state = state.copyWith(
        receipts: receipts,
        stamps: localStamps,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '여행 기록을 불러오지 못했어요.',
      );
    }
  }

  Future<void> shareReceipt(String receiptId) async {
    state = state.copyWith(isSharing: true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(isSharing: false);
  }
}
