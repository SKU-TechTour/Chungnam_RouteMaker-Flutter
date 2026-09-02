import 'package:shared_preferences/shared_preferences.dart';

import '../models/travel_preferences.dart';

class TravelPreferencesRepository {
  static const _partyKey = 'travel_party';
  static const _conceptsKey = 'travel_concepts';
  static const _durationKey = 'trip_duration';
  static const _templateKey = 'route_template';

  Future<TravelPreferences?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final partyName = preferences.getString(_partyKey);
    final conceptNames = preferences.getStringList(_conceptsKey);
    if (partyName == null || conceptNames == null || conceptNames.isEmpty) {
      return null;
    }

    final party = TravelParty.values.where((value) => value.name == partyName);
    final concepts = TravelConcept.values
        .where((value) => conceptNames.contains(value.name))
        .toSet();
    if (party.isEmpty || concepts.isEmpty) return null;
    // 구버전의 companion은 '일반 여행객' 의미였으므로 템플릿 저장값이 없을 때만 이관합니다.
    final resolvedParty =
        party.first == TravelParty.companion &&
            preferences.getString(_templateKey) == null
        ? TravelParty.traveler
        : party.first;
    final durationName = preferences.getString(_durationKey);
    final templateName = preferences.getString(_templateKey);
    final durations = TripDuration.values.where(
      (value) => value.name == durationName,
    );
    final duration =
        resolvedParty == TravelParty.companion && durations.isNotEmpty
        ? durations.first
        : TripDuration.dayTrip;
    final templates = RouteTemplate.values.where(
      (value) => value.name == templateName && value.party == resolvedParty,
    );
    final compatible = RouteTemplate.availableFor(resolvedParty, duration);
    return TravelPreferences(
      party: resolvedParty,
      concepts: concepts,
      duration: duration,
      routeTemplate: templates.isNotEmpty ? templates.first : compatible.first,
    );
  }

  Future<void> save(TravelPreferences value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_partyKey, value.party.name);
    await preferences.setStringList(
      _conceptsKey,
      value.concepts.map((concept) => concept.name).toList(),
    );
    await preferences.setString(_durationKey, value.duration.name);
    await preferences.setString(_templateKey, value.routeTemplate.name);
  }
}
