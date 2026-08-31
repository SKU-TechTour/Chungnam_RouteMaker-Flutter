import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutterprojects/features/my_history/models/receipt.dart';
import 'package:flutterprojects/features/my_history/models/stamp.dart';

/// [SB 화면 4] Spring `GET /api/rewards` — 서버 리워드/영수증 데이터.
class RewardRemoteRepository {
  const RewardRemoteRepository();

  Future<HistorySnapshot> fetchRewards() async {
    final raw = await rootBundle.loadString('assets/mock/history.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return HistorySnapshot(
      receipts: (json['receipts'] as List<dynamic>)
          .map((item) => Receipt.fromJson(item as Map<String, dynamic>))
          .toList(),
      stamps: (json['stamps'] as List<dynamic>)
          .map((item) => Stamp.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HistorySnapshot {
  const HistorySnapshot({required this.receipts, required this.stamps});

  final List<Receipt> receipts;
  final List<Stamp> stamps;
}
