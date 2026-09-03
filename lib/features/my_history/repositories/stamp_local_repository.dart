import 'dart:convert';

import 'package:flutterprojects/features/my_history/models/stamp.dart';
import 'package:flutterprojects/features/my_history/models/receipt.dart';
import 'package:flutterprojects/features/home_curation/models/selected_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [SB 화면 4] 로컬 스탬프/뱃지 저장소.
///
/// SharedPreferences로 기기 내 스탬프 개수·이력을 관리합니다.
class StampLocalRepository {
  static const _stampsKey = 'local_stamps';
  static const _receiptsKey = 'local_receipts';

  Future<List<Receipt>> loadReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_receiptsKey) ?? [];
    return raw
        .map(
          (item) => Receipt.fromJson(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
  }

  Future<List<Stamp>> loadStamps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_stampsKey) ?? [];
    return raw
        .map((e) => Stamp.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> addStamp(Stamp stamp) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_stampsKey) ?? [];
    current.add(jsonEncode(stamp.toJson()));
    await prefs.setStringList(_stampsKey, current);
  }

  Future<int> getStampCount() async {
    final stamps = await loadStamps();
    return stamps.length;
  }

  Future<void> completeRoute(SelectedRoute route) async {
    final completedAt = DateTime.now();
    final receipt = Receipt(
      id: '${route.region}-${completedAt.microsecondsSinceEpoch}',
      title: route.title,
      amount: route.spots.length,
      visitedAt: completedAt,
      region: route.region,
      places: route.spots.map((spot) => spot.name).toList(),
    );
    final prefs = await SharedPreferences.getInstance();
    final receipts = prefs.getStringList(_receiptsKey) ?? [];
    await prefs.setStringList(_receiptsKey, [
      ...receipts,
      jsonEncode(receipt.toJson()),
    ]);
    await addStamp(
      Stamp(
        id: receipt.id,
        label: '${_regionLabel(route.region)} 코스 완주',
        earnedAt: completedAt,
        region: route.region,
      ),
    );
  }

  String _regionLabel(String region) => switch (region) {
    'GONGJU' => '공주',
    'BUYEO' => '부여',
    _ => '논산',
  };
}
