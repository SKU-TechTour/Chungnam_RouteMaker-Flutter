enum TravelParty {
  enlistingSoldier('입대 장병', '논산훈련소 입영 전후 동선을 중심으로 추천해요.'),
  companion('동행 지인', '배웅 전후 함께 머물 코스를 중심으로 추천해요.');

  const TravelParty(this.label, this.description);

  final String label;
  final String description;
}

enum TravelConcept {
  history('역사'),
  food('맛집'),
  stay('숙소'),
  cafe('카페');

  const TravelConcept(this.label);

  final String label;
}

class TravelPreferences {
  const TravelPreferences({required this.party, required this.concepts});

  final TravelParty party;
  final Set<TravelConcept> concepts;
}
