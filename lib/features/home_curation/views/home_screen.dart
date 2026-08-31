import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/route_maker_logo.dart';
import '../../saved/models/saved_course.dart';
import '../../saved/viewmodels/saved_courses_provider.dart';
import '../../travel_preferences/models/travel_preferences.dart';
import '../../travel_preferences/repositories/travel_preferences_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _regionIndex = 0;
  var _sightIndex = 0;
  var _foodIndex = 0;
  var _cafeIndex = 0;
  var _party = TravelParty.companion;
  Set<TravelConcept> _concepts = TravelConcept.values.toSet();

  final _preferencesRepository = TravelPreferencesRepository();

  _RegionCombo get _combo => _combos[_regionIndex];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadRegion);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await _preferencesRepository.load();
    if (preferences == null || !mounted) return;
    setState(() {
      _party = preferences.party;
      _concepts = preferences.concepts;
    });
  }

  Future<void> _selectParty(TravelParty party) async {
    setState(() => _party = party);
    await _preferencesRepository.save(
      TravelPreferences(party: party, concepts: _concepts),
    );
  }

  void _loadRegion() {
    ref
        .read(homeCurationViewModelProvider.notifier)
        .loadCourses(region: _combo.code);
  }

  void _selectRegion(int index) {
    setState(() {
      _regionIndex = index;
      _sightIndex = 0;
      _foodIndex = 0;
      _cafeIndex = 0;
    });
    _loadRegion();
  }

  SavedCourse get _selectedCourse => SavedCourse(
    id: '${_combo.code}-$_sightIndex-$_foodIndex-$_cafeIndex',
    region: _combo.name,
    title: '${_combo.name} 취향 맞춤 3단 콤보',
    places: [
      if (_combo.code == 'NONSAN') '육군훈련소',
      _combo.sights[_sightIndex],
      _combo.foods[_foodIndex],
      _combo.cafes[_cafeIndex],
    ],
  );

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(homeCurationViewModelProvider).isLoading;
    final saved = ref.watch(savedCoursesProvider);
    final selectedCourse = _selectedCourse;
    final isSaved = saved.any((course) => course.id == selectedCourse.id);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      const RouteMakerLogo(compact: true),
                      const Spacer(),
                      IconButton(
                        tooltip: '알림',
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('새로운 여행 소식이 도착하면 알려드릴게요.'),
                              ),
                            ),
                        icon: const Icon(Icons.notifications_none_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '오늘은 충남 어디로\n떠나볼까요?',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 30,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.wb_sunny_outlined,
                        color: AppTheme.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_combo.name} 24°C · 산책하기 좋은 날씨예요',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _RegionSelector(
                    selected: _regionIndex,
                    onSelected: _selectRegion,
                  ),
                  if (_combo.code == 'NONSAN') ...[
                    const SizedBox(height: 16),
                    _NonsanEntryCard(party: _party, onChanged: _selectParty),
                  ],
                  const SizedBox(height: 16),
                  _PreferenceSummary(
                    concepts: _concepts,
                    onEdit: () => context.push('/preferences'),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '맞춤형 3단 콤보',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '각 단계를 눌러 원하는 장소로 바꿔보세요.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (loading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.softMint,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '취향 일치 92%',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ConceptCatalog(combo: _combo, concepts: _concepts),
                  const SizedBox(height: 18),
                  _ComboStep(
                    number: 1,
                    label: '볼거리',
                    icon: Icons.landscape_rounded,
                    color: AppTheme.accent,
                    options: _combo.sights,
                    selectedIndex: _sightIndex,
                    onChanged: (value) => setState(() => _sightIndex = value),
                  ),
                  const _RouteConnector(),
                  _ComboStep(
                    number: 2,
                    label: '먹거리',
                    icon: Icons.restaurant_rounded,
                    color: AppTheme.coral,
                    options: _combo.foods,
                    selectedIndex: _foodIndex,
                    onChanged: (value) => setState(() => _foodIndex = value),
                  ),
                  const _RouteConnector(),
                  _ComboStep(
                    number: 3,
                    label: '쉴거리',
                    icon: Icons.local_cafe_rounded,
                    color: const Color(0xFF6B68D9),
                    options: _combo.cafes,
                    selectedIndex: _cafeIndex,
                    onChanged: (value) => setState(() => _cafeIndex = value),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.route_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 9),
                            const Text(
                              '예상 여행 시간',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _combo.duration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(savedCoursesProvider.notifier)
                                      .toggle(selectedCourse);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isSaved
                                            ? '찜에서 삭제했어요.'
                                            : '찜한 코스에 저장했어요.',
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  isSaved
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                ),
                                label: Text(isSaved ? '저장됨' : '찜하기'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: () => context.go('/map'),
                                icon: const Icon(Icons.navigation_rounded),
                                label: const Text('이 콤보 시작하기'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primary,
                                  minimumSize: const Size.fromHeight(50),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionSelector extends StatelessWidget {
  const _RegionSelector({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: List.generate(_combos.length, (index) {
        final active = selected == index;
        return Expanded(
          child: InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: active ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _combos[index].name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
}

class _ComboStep extends StatelessWidget {
  const _ComboStep({
    required this.number,
    required this.label,
    required this.icon,
    required this.color,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });
  final int number;
  final String label;
  final IconData icon;
  final Color color;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number단계 · $label',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedIndex,
                  isDense: true,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(16),
                  icon: const Icon(Icons.expand_more_rounded),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                  items: List.generate(
                    options.length,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text(options[index]),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) onChanged(value);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 40),
    child: Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 22,
        child: VerticalDivider(width: 2, thickness: 2, color: AppTheme.divider),
      ),
    ),
  );
}

class _RegionCombo {
  const _RegionCombo({
    required this.code,
    required this.name,
    required this.duration,
    required this.sights,
    required this.foods,
    required this.stays,
    required this.cafes,
  });
  final String code;
  final String name;
  final String duration;
  final List<String> sights;
  final List<String> foods;
  final List<String> stays;
  final List<String> cafes;
}

const _combos = [
  _RegionCombo(
    code: 'NONSAN',
    name: '논산',
    duration: '약 4시간 20분',
    sights: ['선샤인 스튜디오', '탑정호 출렁다리', '관촉사', '돈암서원', '강경근대역사문화거리'],
    foods: ['황산옥', '태능초가집갈비', '연산시장 순대', '삼동소바 논산점'],
    stays: ['KT&G 상상마당 논산 아트캠핑빌리지', '스테이인터뷰 강경'],
    cafes: ['강경구락부', '알바노', '카페 아늑'],
  ),
  _RegionCombo(
    code: 'GONGJU',
    name: '공주',
    duration: '약 4시간 40분',
    sights: [
      '무령왕릉과 왕릉원',
      '공산성',
      '국립공주박물관',
      '공주한옥마을',
      '석장리박물관',
      '계룡산도예촌',
      '계룡산자연사박물관',
      '박동진판소리전수관',
      '동학사',
    ],
    foods: ['동해원', '금강관', '새이학가든', '신흥면옥'],
    stays: ['공주한옥마을'],
    cafes: ['베이커리 인화당', '하루카페&밤떡명가'],
  ),
  _RegionCombo(
    code: 'BUYEO',
    name: '부여',
    duration: '약 5시간',
    sights: [
      '백제문화단지',
      '성흥산성 사랑나무',
      '부소산성',
      '국립부여박물관',
      '정림사지박물관',
      '부여 왕릉원(능산리고분군)',
      '서동요테마파크',
      '부여 가림성',
      '무량사',
    ],
    foods: ['장원막국수', '엄가네곰탕', '삼정식당', '나루터식당', '백제향'],
    stays: ['흰구름 밝은달'],
    cafes: ['카페 수북로1945', '무드빌리지'],
  ),
];

class _NonsanEntryCard extends StatelessWidget {
  const _NonsanEntryCard({required this.party, required this.onChanged});

  final TravelParty party;
  final ValueChanged<TravelParty> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppTheme.primary,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.flag_rounded, color: Colors.white),
            SizedBox(width: 9),
            Text(
              '논산 여정의 기준 · 육군훈련소',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          '입영 대상에 따라 훈련소 도착 전후 코스를 다르게 구성해요.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        SegmentedButton<TravelParty>(
          segments: TravelParty.values
              .map(
                (value) => ButtonSegment(
                  value: value,
                  label: Text(value.label),
                  icon: Icon(
                    value == TravelParty.enlistingSoldier
                        ? Icons.person_rounded
                        : Icons.groups_rounded,
                  ),
                ),
              )
              .toList(),
          selected: {party},
          onSelectionChanged: (value) => onChanged(value.first),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.08),
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppTheme.primary
                  : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.shield_outlined, size: 16, color: Colors.white70),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'GPS와 훈련소까지의 거리 계산은 기기 안에서만 처리돼요.',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PreferenceSummary extends StatelessWidget {
  const _PreferenceSummary({required this.concepts, required this.onEdit});

  final Set<TravelConcept> concepts;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          concepts.map((concept) => '#${concept.label}').join('  '),
          maxLines: 2,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      TextButton(onPressed: onEdit, child: const Text('취향 변경')),
    ],
  );
}

class _ConceptCatalog extends StatelessWidget {
  const _ConceptCatalog({required this.combo, required this.concepts});

  final _RegionCombo combo;
  final Set<TravelConcept> concepts;

  @override
  Widget build(BuildContext context) {
    final entries = <(TravelConcept, List<String>)>[
      (TravelConcept.history, combo.sights),
      (TravelConcept.food, combo.foods),
      (TravelConcept.stay, combo.stays),
      (TravelConcept.cafe, combo.cafes),
    ].where((entry) => concepts.contains(entry.$1)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '선택한 취향의 실제 장소',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text(
                '${entry.$1.label}  ·  ${entry.$2.join(' · ')}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
