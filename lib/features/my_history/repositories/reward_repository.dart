import '../models/reward_model.dart';

class RewardRepository {
  Future<RewardModel> getRewards() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return RewardModel(
      stamps: [
        StampModel(id: '1', region: 'GONGJU', courseName: '공주 로컬 데이트 코스', completedAt: DateTime.now().subtract(const Duration(days: 5))),
        StampModel(id: '2', region: 'NONSAN', courseName: '논산 단기 고효율 코스', completedAt: DateTime.now().subtract(const Duration(days: 10))),
      ],
      badges: [
        BadgeModel(id: '1', name: '공주 완주 배지', description: '공주 코스를 완주했어요!'),
        BadgeModel(id: '2', name: 'Chak 가맹점', description: '충남 지역화폐 할인 혜택', isChakPartner: true),
      ],
    );
  }

  Future<String> generateShareCard(String courseId) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'https://routemaker.app/share/$courseId';
  }
}
