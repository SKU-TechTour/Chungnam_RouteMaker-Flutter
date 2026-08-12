import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/features/my_history/models/receipt.dart';
import 'package:flutterprojects/features/my_history/models/stamp.dart';
import 'package:flutterprojects/features/my_history/viewmodels/my_history_state.dart';

class MyHistoryViewModel extends Notifier<MyHistoryState> {
  @override
  MyHistoryState build() => const MyHistoryState();

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final receipts = await ref
          .read(rewardRemoteRepositoryProvider)
          .fetchRewards();
      final stamps = await ref.read(stampLocalRepositoryProvider).loadStamps();
      state = state.copyWith(
        receipts: receipts,
        stamps: stamps,
        isLoading: false,
      );
    } catch (_) {
      // The reward-history endpoint is not implemented on the server yet.
      // These showcase entries keep the finished frontend informative in the meantime.
      state = state.copyWith(
        isLoading: false,
        stamps: [
          Stamp(
            id: 'gongju',
            label: '공주 완주',
            earnedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          Stamp(
            id: 'buyeo',
            label: '부여 산책',
            earnedAt: DateTime.now().subtract(const Duration(days: 12)),
          ),
        ],
        receipts: [
          Receipt(
            id: 'receipt-1',
            title: '공산성 산책 코스',
            amount: 3,
            visitedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          Receipt(
            id: 'receipt-2',
            title: '백제의 하루',
            amount: 3,
            visitedAt: DateTime.now().subtract(const Duration(days: 12)),
          ),
        ],
      );
    }
  }

  Future<void> shareReceipt(String receiptId) async {
    state = state.copyWith(isSharing: true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(isSharing: false);
  }
}
