import 'package:flutterprojects/features/my_history/models/receipt.dart';

/// [SB 화면 4] Spring `GET /api/rewards` — 서버 리워드/영수증 데이터.
class RewardRemoteRepository {
  const RewardRemoteRepository();

  /// The current server exposes stamp and share-card mutations only; it does
  /// not provide a reward-history endpoint yet.
  Future<List<Receipt>> fetchRewards() => Future.error(
    UnsupportedError('Reward history API is not available on the server'),
  );
}
