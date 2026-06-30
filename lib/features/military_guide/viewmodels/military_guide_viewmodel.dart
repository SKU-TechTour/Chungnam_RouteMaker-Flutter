import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/features/military_guide/viewmodels/military_guide_state.dart';

/// [SB 화면 2] 복귀 카운트다운 타이머 ViewModel.
class MilitaryGuideViewModel extends Notifier<MilitaryGuideState> {
  Timer? _timer;

  @override
  MilitaryGuideState build() {
    ref.onDispose(_timer?.cancel);
    return const MilitaryGuideState();
  }

  Future<void> startCountdown() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final minutes =
          await ref.read(militaryRepositoryProvider).fetchSafeTimeMinutes();
      var secondsLeft = minutes * 60;
      state = state.copyWith(secondsLeft: secondsLeft, isLoading: false);

      await ref
          .read(militaryRepositoryProvider)
          .syncLiveWidget(secondsLeft);

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.secondsLeft <= 0) {
          _timer?.cancel();
          return;
        }
        final next = state.secondsLeft - 1;
        state = state.copyWith(secondsLeft: next);
        ref.read(militaryRepositoryProvider).syncLiveWidget(next);
      });
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void stopCountdown() {
    _timer?.cancel();
  }
}
