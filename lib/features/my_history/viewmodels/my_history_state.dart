import 'package:flutterprojects/features/my_history/models/receipt.dart';
import 'package:flutterprojects/features/my_history/models/stamp.dart';

/// [SB 화면 4] 여행 기록·리워드 View 상태.
class MyHistoryState {
  const MyHistoryState({
    this.receipts = const [],
    this.stamps = const [],
    this.isSharing = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Receipt> receipts;
  final List<Stamp> stamps;
  final bool isSharing;
  final bool isLoading;
  final String? errorMessage;

  int get stampCount => stamps.length;

  MyHistoryState copyWith({
    List<Receipt>? receipts,
    List<Stamp>? stamps,
    bool? isSharing,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyHistoryState(
      receipts: receipts ?? this.receipts,
      stamps: stamps ?? this.stamps,
      isSharing: isSharing ?? this.isSharing,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
