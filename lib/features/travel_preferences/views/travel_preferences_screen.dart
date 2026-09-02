import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../models/travel_preferences.dart';
import '../repositories/travel_preferences_repository.dart';

class TravelPreferencesScreen extends StatefulWidget {
  const TravelPreferencesScreen({super.key});

  @override
  State<TravelPreferencesScreen> createState() =>
      _TravelPreferencesScreenState();
}

class _TravelPreferencesScreenState extends State<TravelPreferencesScreen> {
  final _repository = TravelPreferencesRepository();
  TravelParty? _party;
  TripDuration _duration = TripDuration.dayTrip;
  RouteTemplate? _routeTemplate;
  final Set<TravelConcept> _concepts = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await _repository.load();
    if (saved == null || !mounted) return;
    setState(() {
      _party = saved.party;
      _duration = saved.duration;
      _routeTemplate = saved.routeTemplate;
      _concepts.addAll(saved.concepts);
    });
  }

  Future<void> _continue() async {
    if (_party == null || _routeTemplate == null || _concepts.isEmpty) return;
    setState(() => _saving = true);
    await _repository.save(
      TravelPreferences(
        party: _party!,
        concepts: _concepts,
        duration: _duration,
        routeTemplate: _routeTemplate!,
      ),
    );
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppTheme.softMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.military_tech_rounded,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              '누구의 논산 여정인가요?',
              style: TextStyle(
                fontSize: 28,
                height: 1.2,
                letterSpacing: -1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              '육군훈련소 입영 일정을 기준으로 알맞은 동선과 여행지를 연결해드려요.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ...TravelParty.values.map(
              (party) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PartyCard(
                  party: party,
                  selected: _party == party,
                  onTap: () => setState(() {
                    _party = party;
                    _duration = TripDuration.dayTrip;
                    _routeTemplate = RouteTemplate.availableFor(
                      party,
                      _duration,
                    ).first;
                  }),
                ),
              ),
            ),
            if (_party == TravelParty.companion) ...[
              const SizedBox(height: 14),
              const Text(
                '여행 일정',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              SegmentedButton<TripDuration>(
                segments: TripDuration.values
                    .map(
                      (duration) => ButtonSegment(
                        value: duration,
                        label: Text(duration.label),
                      ),
                    )
                    .toList(),
                selected: {_duration},
                onSelectionChanged: (selected) => setState(() {
                  _duration = selected.first;
                  _routeTemplate = RouteTemplate.availableFor(
                    _party!,
                    _duration,
                  ).first;
                }),
              ),
            ],
            if (_party != null) ...[
              const SizedBox(height: 24),
              const Text(
                '원하는 코스 타입',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...RouteTemplate.availableFor(_party!, _duration).map(
                (template) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _RouteTemplateCard(
                    template: template,
                    selected: _routeTemplate == template,
                    onTap: () => setState(() => _routeTemplate = template),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              '관심 컨셉을 골라주세요',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              '여러 개를 선택할 수 있어요.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: TravelConcept.values.map((concept) {
                final selected = _concepts.contains(concept);
                return FilterChip(
                  selected: selected,
                  showCheckmark: false,
                  avatar: Icon(
                    _conceptIcon(concept),
                    size: 18,
                    color: selected ? Colors.white : AppTheme.textSecondary,
                  ),
                  label: Text(concept.label),
                  selectedColor: AppTheme.accent,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected ? AppTheme.accent : AppTheme.divider,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  onSelected: (_) => setState(() {
                    selected
                        ? _concepts.remove(concept)
                        : _concepts.add(concept);
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FA),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: AppTheme.primary),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      '현재 위치와 관광지 간 거리 계산은 기기 안에서만 처리하며 GPS 좌표를 서버로 전송하지 않아요.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.45,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed:
                  _party != null &&
                      _routeTemplate != null &&
                      _concepts.isNotEmpty &&
                      !_saving
                  ? _continue
                  : null,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('내 코스 보러 가기'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({
    required this.party,
    required this.selected,
    required this.onTap,
  });

  final TravelParty party;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppTheme.softMint : Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(switch (party) {
              TravelParty.enlistingSoldier => Icons.military_tech_rounded,
              TravelParty.companion => Icons.groups_rounded,
              TravelParty.traveler => Icons.luggage_rounded,
            }, color: selected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    party.label,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    party.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
          ],
        ),
      ),
    ),
  );
}

class _RouteTemplateCard extends StatelessWidget {
  const _RouteTemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final RouteTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: selected ? AppTheme.softMint : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppTheme.primary : AppTheme.divider,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              template.typeLabel,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  template.summary,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
        ],
      ),
    ),
  );
}

IconData _conceptIcon(TravelConcept concept) => switch (concept) {
  TravelConcept.healing => Icons.spa_rounded,
  TravelConcept.activity => Icons.directions_walk_rounded,
  TravelConcept.history => Icons.account_balance_rounded,
  TravelConcept.food => Icons.restaurant_rounded,
  TravelConcept.cafe => Icons.local_cafe_rounded,
};
