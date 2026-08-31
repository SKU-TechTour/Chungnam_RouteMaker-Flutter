import 'package:shared_preferences/shared_preferences.dart';

import '../models/travel_preferences.dart';

class TravelPreferencesRepository {
  static const _partyKey = 'travel_party';
  static const _conceptsKey = 'travel_concepts';

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
    return TravelPreferences(party: party.first, concepts: concepts);
  }

  Future<void> save(TravelPreferences value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_partyKey, value.party.name);
    await preferences.setStringList(
      _conceptsKey,
      value.concepts.map((concept) => concept.name).toList(),
    );
  }
}
