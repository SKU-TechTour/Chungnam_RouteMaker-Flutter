/// 로컬 스탬프/뱃지 모델.
class Stamp {
  const Stamp({
    required this.id,
    required this.label,
    required this.earnedAt,
  });

  factory Stamp.fromJson(Map<String, dynamic> json) {
    return Stamp(
      id: json['id'] as String,
      label: json['label'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'earnedAt': earnedAt.toIso8601String(),
      };

  final String id;
  final String label;
  final DateTime earnedAt;
}
