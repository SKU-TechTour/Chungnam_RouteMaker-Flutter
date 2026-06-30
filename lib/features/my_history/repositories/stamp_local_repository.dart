import 'dart:convert';

import 'package:flutterprojects/features/my_history/models/stamp.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [SB 화면 4] 로컬 스탬프/뱃지 저장소.
///
/// SharedPreferences로 기기 내 스탬프 개수·이력을 관리합니다.
class StampLocalRepository {
  static const _stampsKey = 'local_stamps';

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
}
