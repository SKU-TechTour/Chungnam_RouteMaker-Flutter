## Chungnam RouteMaker — Flutter Frontend
Frontend: Flutter (MVVM + Feature-first)
Backend: Spring (DDD / Layered Architecture)
Repository: SKU-TechTour/Chungnam_RouteMaker-Flutter

### 1. 아키텍처 개요
이 프로젝트는 MVVM(Model-View-ViewModel) 패턴을 기반으로, 화면(스토리보드) 단위로 모듈을 나눈 Feature-first 구조를 사용합니다.

Spring Backend는 DDD 계층(Controller → Service → Repository → Entity)으로 설계하고, Flutter Frontend는 화면 상태와 UI를 MVVM으로 분리합니다. 두 프로젝트는 REST API(JSON over HTTP) 로 통신합니다.

┌─────────────────────────────────────────────────────────────┐
│                    Flutter App (MVVM)                        │
│  View ──→ ViewModel ──→ Repository ──→ Dio ──→ Spring API   │
│    ↑          │              │                               │
│    └──────────┘              ├── MethodChannel (Native)      │
│                              └── SharedPreferences (Local)   │
└─────────────────────────────────────────────────────────────┘
                              │ HTTP (JSON)
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Spring Backend (DDD)                       │
│  Controller ──→ Service ──→ Repository ──→ DB / External    │
└─────────────────────────────────────────────────────────────┘
계층별 역할
Flutter 계층	역할	Spring 대응
View
UI 렌더링, 사용자 입력을 ViewModel에 전달
없음 (UI 전용)
ViewModel
화면 상태 관리, UI 이벤트 처리, Repository 호출
Controller가 받는 요청의 "화면 표현"
Repository
API·로컬·네이티브 데이터 소스 추상화
Service를 HTTP로 호출하는 Client 역할
Model
JSON ↔ Dart 객체 변환
DTO / Entity
핵심 설계 원칙
View는 ViewModel만 안다 — Dio, API URL, MethodChannel을 View에서 직접 호출하지 않음
ViewModel은 Repository만 안다 — HTTP 세부사항은 Repository에 위임
Feature 간 직접 import 금지 — 공통 코드는 core/로, feature끼리는 독립
의존성 주입은 core/di/providers.dart 한곳에서 — Riverpod Provider로 연결
스토리보드(SB) 화면 = feature 1개 — 팀원별 담당 feature 분리 가능
2. 폴더 구조
lib/
├── main.dart                              # 앱 진입점
│
├── core/                                  # ⚙️ 전역 공통 모듈 (feature 무관)
│   ├── constants/
│   │   └── api_constants.dart             # Spring baseUrl + API 엔드포인트
│   ├── network/
│   │   ├── dio_client.dart                # Dio 싱글톤 (HTTP 클라이언트)
│   │   └── api_exception.dart             # 공통 API 예외 타입
│   ├── utils/
│   │   └── location_util.dart             # GPS 좌표 획득 (geolocator)
│   ├── theme/
│   │   └── app_theme.dart                 # Material 3 공통 테마
│   ├── routing/
│   │   └── app_router.dart                # go_router 화면 라우팅
│   ├── di/
│   │   └── providers.dart                 # Riverpod DI (Repository·ViewModel 연결)
│   └── widgets/
│       ├── loading_widget.dart            # 공통 로딩 UI
│       └── error_widget.dart              # 공통 에러 + 재시도 UI
│
└── features/                              # 🚀 SB 화면별 feature 모듈
    ├── home_curation/                     # [SB 1] 홈 큐레이션·날씨 셔플
    ├── military_guide/                    # [SB 2] 훈련소 가이드·라이브 위젯
    ├── map_search/                        # [SB 3] 지도 GPS·동반자 필터
    └── my_history/                        # [SB 4] 여행 기록·로컬 리워드
Feature 내부 표준 구조
features/{feature_name}/
├── models/              # Model — API JSON ↔ Dart 객체
├── repositories/        # Data — API/로컬/네이티브 호출
├── viewmodels/          # ViewModel — 상태(State) + 이벤트 처리(Notifier)
│   ├── {name}_state.dart
│   └── {name}_viewmodel.dart
└── views/               # View — Screen + 재사용 위젯
    ├── {name}_screen.dart
    └── widgets/
military_guide만 네이티브 연동을 위해 추가 레이어가 있습니다:

features/military_guide/
└── data/
    └── platform/
        └── live_widget_channel.dart   # Android/iOS MethodChannel
3. 앱 시작 흐름 (Bootstrap)
main()
  └── ProviderScope          ← Riverpod DI 컨테이너 시작
        └── MyApp
              ├── AppTheme.light          ← core/theme
              ├── appRouter (GoRouter)    ← core/routing
              └── builder: CountdownWidget  ← military_guide (전역 위젯)
main.dart는 테마, 라우팅, DI만 연결하는 진입점입니다. 비즈니스 로직은 feature에만 존재합니다.

4. 내부 소통 구조 (MVVM + Riverpod)
4.1 의존성 주입 (DI) 체인
모든 의존 관계는 core/di/providers.dart에서 한 번에 정의됩니다.

dioProvider
  ├── courseRepositoryProvider        → HomeCurationViewModel
  ├── militaryRepositoryProvider      → MilitaryGuideViewModel
  │     └── liveWidgetChannelProvider
  ├── placeRepositoryProvider         → MapSearchViewModel
  └── rewardRemoteRepositoryProvider  → MyHistoryViewModel
locationUtilProvider                → MapSearchViewModel
stampLocalRepositoryProvider        → MyHistoryViewModel
View는 ViewModel Provider만 사용합니다:

// View에서의 사용 패턴
final state = ref.watch(homeCurationViewModelProvider);       // 상태 구독 (UI 갱신)
final notifier = ref.read(homeCurationViewModelProvider.notifier); // 이벤트 호출
ref.watch → 상태 변경 시 UI 자동 rebuild
ref.read → 버튼 클릭 등 일회성 이벤트 호출
4.2 View ↔ ViewModel ↔ Repository 흐름 (예: home_curation)
[사용자] "Plan B 셔플" 버튼 클릭
    │
    ▼
HomeScreen (View)
    │  ref.read(...notifier).shuffleToNext()
    ▼
HomeCurationViewModel
    │  state = state.copyWith(currentIndex: next)
    ▼
HomeScreen (View) — ref.watch로 state 변경 감지 → UI rebuild
[화면 진입] initState
    │
    ▼
HomeScreen (View)
    │  ref.read(...notifier).loadCourses()
    ▼
HomeCurationViewModel
    │  state = loading
    │  ref.read(courseRepositoryProvider).fetchCourses()
    ▼
CourseRepository
    │  dio.get('/api/courses')
    ▼
Spring Backend
    │  JSON 응답
    ▼
Course.fromJson() → List<Course>
    │
    ▼
HomeCurationViewModel
    │  state = { courses, isLoading: false }
    ▼
HomeScreen — ComboCard 렌더링
4.3 State 클래스 패턴
각 ViewModel은 불변(immutable) State 클래스를 가집니다:

// home_curation_state.dart
class HomeCurationState {
  final List<Course> courses;
  final int currentIndex;
  final bool isLoading;
  final String? errorMessage;
  HomeCurationState copyWith({ ... });  // 상태 복사·갱신
}
ViewModel은 Notifier<State>를 상속하고, state = state.copyWith(...)로 상태를 갱신합니다.

5. 외부 소통 구조
5.1 Flutter ↔ Spring Backend (HTTP)
Repository
    │
    ▼
DioClient.instance.dio          ← core/network/dio_client.dart
    │  baseUrl: ApiConstants.baseUrl
    │  headers: Content-Type: application/json
    │  interceptor: DioException → ApiException 변환
    ▼
Spring REST API
API 엔드포인트 매핑 (core/constants/api_constants.dart):

Feature	HTTP	Endpoint	설명
home_curation
GET
/api/courses
3단 콤보 코스 목록
military_guide
GET
/api/military/safe-time
복귀 가능까지 남은 시간(분)
map_search
POST
/api/places/filter
GPS + 필터 조건으로 장소 검색
my_history
GET
/api/rewards
서버 리워드/영수증 목록
Spring ↔ Flutter JSON 계약 예시:

// GET /api/courses
{ "courses": [{ "id": "1", "title": "...", "spots": ["A","B","C"], "weatherTag": "맑음" }] }
// GET /api/military/safe-time
{ "minutesLeft": 120 }
// POST /api/places/filter
// Request:  { "lat": 36.3, "lng": 127.4, "petFriendly": true, "strollerAccessible": false }
// Response: { "places": [{ "id": "1", "name": "...", "type": "cafe", "lat": ..., "lng": ... }] }
// GET /api/rewards
{ "receipts": [{ "id": "1", "title": "...", "amount": 15000, "visitedAt": "2026-06-30" }] }
baseUrl은 현재 http://localhost:8080입니다.
실기기 테스트 시 --dart-define 또는 flavor로 dev/staging/prod 분리하세요.

5.2 Flutter ↔ Native (MethodChannel)
military_guide feature에서 Android/iOS 라이브 위젯과 통신합니다.

CountdownWidget (View)
    │  ref.watch(militaryGuideViewModelProvider)
    ▼
MilitaryGuideViewModel
    │  repository.syncLiveWidget(secondsLeft)
    ▼
MilitaryRepository
    │  liveWidgetChannel.updateCountdown(seconds)
    ▼
LiveWidgetChannel                    ← data/platform/ (View 밖)
    │  MethodChannel('com.techtour/live_widget')
    ▼
Android / iOS Native Code
중요: MethodChannel은 View가 아닌 data/platform/ 레이어에 위치합니다. View는 ViewModel만 구독합니다.

5.3 Flutter ↔ Local Storage (SharedPreferences)
my_history feature에서 로컬 스탬프/뱃지를 기기 내에 저장합니다.

MyHistoryViewModel.loadHistory()
    ├── rewardRemoteRepository.fetchRewards()   → Spring GET /api/rewards
    └── stampLocalRepository.loadStamps()       → SharedPreferences (로컬)
ViewModel이 원격 + 로컬 Repository를 조합하여 하나의 State로 View에 전달합니다.

5.4 Flutter ↔ Device GPS
map_search feature에서 주변 장소 검색 시 GPS 좌표가 필요합니다.

MapSearchViewModel.searchNearby()
    ├── locationUtil.getCurrentPosition()       → geolocator (core/utils)
    └── placeRepository.filterPlaces(request)   → Spring POST /api/places/filter
GPS 권한 요청·좌표 획득은 core/utils/location_util.dart에서 처리하고, ViewModel은 결과만 사용합니다.

6. Feature별 상세
[SB 1] home_curation — 홈 큐레이션·날씨 셔플
파일	계층	역할
models/course.dart
Model
3단 콤보 코스 (id, title, spots, weatherTag)
repositories/course_repository.dart
Repository
GET /api/courses
viewmodels/home_curation_state.dart
State
courses, currentIndex, isLoading, error
viewmodels/home_curation_viewmodel.dart
ViewModel
loadCourses, shuffleToNext, onSwipe
views/home_screen.dart
View
메인 화면
views/widgets/combo_card.dart
View
코스 카드 UI
라우트: /

[SB 2] military_guide — 훈련소 가이드·라이브 위젯
파일	계층	역할
data/platform/live_widget_channel.dart
Platform
MethodChannel 네이티브 통신
repositories/military_repository.dart
Repository
API + 라이브 위젯 동기화
viewmodels/military_guide_viewmodel.dart
ViewModel
1초 Timer 카운트다운
views/countdown_widget.dart
View
카운트다운 UI
특이사항: CountdownWidget은 main.dart의 builder에도 삽입되어 모든 화면 하단에 표시됩니다 (외부 위젯 SB 요구사항).

라우트: 별도 화면 없음 (전역 위젯)

[SB 3] map_search — 지도 GPS·동반자 필터
파일	계층	역할
models/place.dart
Model
Place + PlaceFilterRequest
repositories/place_repository.dart
Repository
POST /api/places/filter
viewmodels/map_search_viewmodel.dart
ViewModel
petFriendly/strollerAccessible 필터
views/map_screen.dart
View
지도 화면 (지도 SDK 연동 지점)
views/filter_bottom_sheet.dart
View
필터 바텀시트
라우트: /map

[SB 4] my_history — 여행 기록·로컬 리워드
파일	계층	역할
models/receipt.dart
Model
영수증 카드 (서버)
models/stamp.dart
Model
스탬프/뱃지 (로컬)
repositories/reward_remote_repository.dart
Repository
GET /api/rewards
repositories/stamp_local_repository.dart
Repository
SharedPreferences
viewmodels/my_history_viewmodel.dart
ViewModel
loadHistory, shareReceipt
views/receipt_share_screen.dart
View
원터치 공유
views/stamp_history_screen.dart
View
스탬프 이력
라우트: /history/receipt, /history/stamps

7. 라우팅
go_router 기반. 모든 라우트는 core/routing/app_router.dart에 정의됩니다.

경로	화면	Feature
/
HomeScreen
home_curation
/map
MapScreen
map_search
/history/receipt
ReceiptShareScreen
my_history
/history/stamps
StampHistoryScreen
my_history
화면 이동: context.go(AppRoutes.map) 또는 context.push(...)

8. 사용 패키지
패키지	버전	용도
flutter_riverpod
^2.6.1
ViewModel(Notifier) + DI(Provider)
dio
^5.8.0
Spring HTTP 통신
go_router
^15.1.2
선언적 라우팅
geolocator
^14.0.1
GPS 좌표 획득
shared_preferences
^2.5.3
로컬 스탬프 저장
9. 코딩 규칙
해야 할 것
View에서 ref.watch(viewModelProvider)로 상태 구독
ViewModel에서 ref.read(repositoryProvider)로 데이터 요청
API URL은 ApiConstants에만 정의
새 feature 추가 시 providers.dart + app_router.dart + api_constants.dart 3곳 업데이트
공통 UI는 core/widgets/, feature 전용 UI는 views/widgets/
하지 말아야 할 것
View에서 Dio / MethodChannel / SharedPreferences 직접 호출
feature A에서 feature B의 ViewModel 직접 import
ViewModel에서 BuildContext 사용
Repository에서 UI 관련 코드 작성
10. 새 Feature 추가 체크리스트
lib/features/{name}/ 아래 models, repositories, viewmodels, views 생성
core/constants/api_constants.dart에 엔드포인트 추가
core/di/providers.dart에 Repository Provider + ViewModel NotifierProvider 등록
core/routing/app_router.dart에 GoRoute 추가
(선택) test/features/{name}/에 ViewModel·Repository 단위 테스트 작성
11. 테스트 구조 (권장)
test/
├── core/
│   └── network/
└── features/
    ├── home_curation/
    │   ├── viewmodels/home_curation_viewmodel_test.dart
    │   └── repositories/course_repository_test.dart
    ├── map_search/
    ├── military_guide/
    └── my_history/
ViewModel은 Mock Repository로, Repository는 Mock Dio로 단위 테스트합니다. View는 Widget Test로 smoke test합니다.

12. Spring Backend와의 역할 분담
┌──────────────────┬─────────────────────────┬──────────────────────────┐
│     관심사        │   Flutter (MVVM)         │   Spring (DDD)           │
├──────────────────┼─────────────────────────┼──────────────────────────┤
│ UI / 화면 상태    │ View + ViewModel         │ —                        │
│ 비즈니스 로직     │ ViewModel (Presentation) │ Service (Domain)         │
│ 데이터 접근       │ Repository (HTTP Client) │ Repository (JPA/Query)   │
│ 데이터 모델       │ Model (fromJson)         │ DTO / Entity             │
│ API 엔드포인트    │ ApiConstants (소비)      │ Controller (제공)        │
│ 네이티브 연동     │ MethodChannel            │ —                        │
│ 로컬 저장         │ SharedPreferences        │ —                        │
└──────────────────┴─────────────────────────┴──────────────────────────┘
13. 로컬 실행
# 의존성 설치
flutter pub get
# Spring Backend 실행 (별도 프로젝트, port 8080)
# ./gradlew bootRun
# Flutter 실행
flutter run
# API baseUrl 변경 (실기기 등)
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080
14. 관련 문서
상세 아키텍처 가이드: ARCHITECTURE.md
Spring Backend: (Spring 프로젝트 README 링크 추가)
