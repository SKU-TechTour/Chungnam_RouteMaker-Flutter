enum TravelParty {
  enlistingSoldier('논산훈련소 입영객', '오후 1시 입소에 맞춘 입영 전 동선을 추천해요.'),
  companion('논산훈련소 입영객 지인', '배웅 이후까지 이어지는 당일 또는 1박 2일 여행이에요.'),
  traveler('일반 여행객', '공주·부여·논산의 관광 취향을 중심으로 추천해요.');

  const TravelParty(this.label, this.description);

  final String label;
  final String description;
}

enum TripDuration {
  dayTrip('당일치기'),
  overnight('1박 2일');

  const TripDuration(this.label);
  final String label;
}

enum RouteTemplate {
  enlisteeA(
    'ENLISTEE_A',
    TravelParty.enlistingSoldier,
    TripDuration.dayTrip,
    '타입 A',
    '든든한 출발형',
    '맛집 ➔ 카페 ➔ 논산훈련소',
  ),
  enlisteeB(
    'ENLISTEE_B',
    TravelParty.enlistingSoldier,
    TripDuration.dayTrip,
    '타입 B',
    '직진형',
    '맛집 ➔ 논산훈련소',
  ),
  enlisteeC(
    'ENLISTEE_C',
    TravelParty.enlistingSoldier,
    TripDuration.dayTrip,
    '타입 C',
    '여유형',
    '카페 ➔ 맛집 ➔ 논산훈련소',
  ),
  companionDayA(
    'COMPANION_DAY_A',
    TravelParty.companion,
    TripDuration.dayTrip,
    '타입 A',
    '전통 힐링형',
    '맛집 ➔ 훈련소 ➔ 유적지 ➔ 카페 ➔ 맛집 ➔ 유적지',
  ),
  companionDayB(
    'COMPANION_DAY_B',
    TravelParty.companion,
    TripDuration.dayTrip,
    '타입 B',
    '자연 뷰 중심형',
    '맛집 ➔ 훈련소 ➔ 카페 ➔ 유적지 ➔ 맛집',
  ),
  companionDayC(
    'COMPANION_DAY_C',
    TravelParty.companion,
    TripDuration.dayTrip,
    '타입 C',
    '백제 문화 연계형',
    '맛집 ➔ 훈련소 ➔ 유적지 ➔ 카페 ➔ 맛집',
  ),
  companionOvernightA(
    'COMPANION_OVERNIGHT_A',
    TravelParty.companion,
    TripDuration.overnight,
    '타입 A',
    '부여·공주 백제 투어',
    '논산 입소 배웅 후 부여 1박, 다음 날 공주까지',
  ),
  companionOvernightB(
    'COMPANION_OVERNIGHT_B',
    TravelParty.companion,
    TripDuration.overnight,
    '타입 B',
    '논산 로컬 힐링 & 휴식',
    '탑정호·선샤인랜드·돈암서원과 함께하는 논산 1박',
  ),
  travelerFlexible(
    'TRAVELER_FLEX',
    TravelParty.traveler,
    TripDuration.dayTrip,
    '취향 맞춤',
    '충남 자유 여행',
    '유적지 ➔ 맛집 ➔ 카페',
  );

  const RouteTemplate(
    this.apiCode,
    this.party,
    this.duration,
    this.typeLabel,
    this.title,
    this.summary,
  );

  final String apiCode;
  final TravelParty party;
  final TripDuration duration;
  final String typeLabel;
  final String title;
  final String summary;

  static List<RouteTemplate> availableFor(
    TravelParty party,
    TripDuration duration,
  ) => values
      .where(
        (template) => template.party == party && template.duration == duration,
      )
      .toList();
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
  const TravelPreferences({
    required this.party,
    required this.concepts,
    required this.duration,
    required this.routeTemplate,
  });

  final TravelParty party;
  final Set<TravelConcept> concepts;
  final TripDuration duration;
  final RouteTemplate routeTemplate;
}
