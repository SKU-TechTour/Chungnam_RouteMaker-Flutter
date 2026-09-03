/// 영수증 카드 공유 데이터 모델.
class Receipt {
  const Receipt({
    required this.id,
    required this.title,
    required this.amount,
    required this.visitedAt,
    required this.region,
    required this.places,
    this.imageUrl,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: json['amount'] as int,
      visitedAt: DateTime.parse(json['visitedAt'] as String),
      region: json['region'] as String? ?? 'NONSAN',
      places: (json['places'] as List<dynamic>? ?? const [])
          .map((place) => place.toString())
          .toList(),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  final String id;
  final String title;
  final int amount;
  final DateTime visitedAt;
  final String region;
  final List<String> places;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'visitedAt': visitedAt.toIso8601String(),
    'region': region,
    'places': places,
    'imageUrl': imageUrl,
  };
}
