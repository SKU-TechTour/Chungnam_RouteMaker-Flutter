enum TravelParty {
  enlistingSoldier('입대 장병', '논산훈련소 입영 전후 동선을 중심으로 추천해요.'),
  companion('동행지인 / 여행객', '배웅 또는 일반 여행 목적에 맞는 코스를 추천해요.');

  const TravelParty(this.label, this.description);

  final String label;
  final String description;
}

enum TravelConcept {
  healing('힐링'),
  activity('액티비티'),
  history('역사'),
  food('맛집'),
  cafe('카페');

  const TravelConcept(this.label);

  final String label;
}

class TravelPreferences {
  const TravelPreferences({required this.party, required this.concepts});

  final TravelParty party;
  final Set<TravelConcept> concepts;
}
