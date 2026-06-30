/// 영수증 카드 공유 데이터 모델.
class Receipt {
  const Receipt({
    required this.id,
    required this.title,
    required this.amount,
    required this.visitedAt,
    this.imageUrl,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: json['amount'] as int,
      visitedAt: DateTime.parse(json['visitedAt'] as String),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  final String id;
  final String title;
  final int amount;
  final DateTime visitedAt;
  final String? imageUrl;
}
