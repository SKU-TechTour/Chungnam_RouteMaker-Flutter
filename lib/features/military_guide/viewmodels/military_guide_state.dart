/// [SB 화면 2] 복귀 카운트다운 View 상태.
class MilitaryGuideState {
  const MilitaryGuideState({
    this.secondsLeft = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final int secondsLeft;
  final bool isLoading;
  final String? errorMessage;

  MilitaryGuideState copyWith({
    int? secondsLeft,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MilitaryGuideState(
      secondsLeft: secondsLeft ?? this.secondsLeft,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
