# Flutter MVVM 아키텍처 가이드

> Frontend: Flutter (MVVM) · Backend: Spring (DDD/Layered)

## 데이터 흐름

```
View  →  ViewModel  →  Repository  →  Spring API
  ↑          │              │
  └──────────┘              └── MethodChannel / SharedPreferences (로컬)
```

| 계층 | 역할 | Spring 대응 |
|------|------|-------------|
| **View** | UI 렌더링, 사용자 이벤트 전달 | (없음) |
| **ViewModel** | 화면 상태·비즈니스 로직 (Presentation) | Controller가 받는 요청의 화면 표현 |
| **Repository** | API/로컬 데이터 소스 추상화 | Service 호출 (HTTP Client) |
| **Model** | JSON ↔ Dart 객체 | DTO / Entity |

---

## 폴더 구조

```
lib/
├── main.dart                          # ProviderScope + GoRouter 진입점
├── core/                              # 전역 공통 모듈
│   ├── constants/api_constants.dart   # Spring API URL·엔드포인트
│   ├── network/                       # DioClient, ApiException
│   ├── utils/location_util.dart       # GPS 좌표 획득
│   ├── theme/app_theme.dart           # SB 공통 Material 테마
│   ├── routing/app_router.dart        # 화면 라우트 (go_router)
│   ├── di/providers.dart              # Riverpod DI — Repository·ViewModel 연결
│   └── widgets/                       # 공통 Loading, Error 위젯
│
└── features/                          # SB 화면별 feature 모듈
    ├── home_curation/                 # [SB 1] 홈 큐레이션·날씨 셔플
    ├── military_guide/                # [SB 2] 훈련소 가이드·라이브 위젯
    ├── map_search/                    # [SB 3] 지도 GPS·동반자 필터
    └── my_history/                    # [SB 4] 여행 기록·로컬 리워드
```

각 feature 내부:

```
feature/
├── models/          # API JSON ↔ Dart (Model)
├── repositories/    # GET/POST 호출 (Data)
├── viewmodels/      # 상태 + 이벤트 처리 (ViewModel)
└── views/           # Screen + widgets (View)
```

`military_guide`만 추가로:

```
data/platform/live_widget_channel.dart   # MethodChannel (View 밖)
```

---

## Feature별 설명

### 1. home_curation — [SB 화면 1]

| 파일 | 설명 |
|------|------|
| `models/course.dart` | 3단 콤보 코스 모델 |
| `repositories/course_repository.dart` | `GET /api/courses` |
| `viewmodels/home_curation_viewmodel.dart` | 카드 스와이프, Plan B 셔플 |
| `views/home_screen.dart` | 메인 화면 |
| `views/widgets/combo_card.dart` | 코스 카드 UI |

### 2. military_guide — [SB 화면 2 + 외부 위젯]

| 파일 | 설명 |
|------|------|
| `data/platform/live_widget_channel.dart` | Android/iOS 라이브 위젯 MethodChannel |
| `repositories/military_repository.dart` | `GET /api/military/safe-time` + 채널 동기화 |
| `viewmodels/military_guide_viewmodel.dart` | 복귀 카운트다운 타이머 |
| `views/countdown_widget.dart` | 카운트다운 UI (main.dart builder에도 삽입) |

### 3. map_search — [SB 화면 3]

| 파일 | 설명 |
|------|------|
| `models/place.dart` | 관광지/식당/카페 + 필터 요청 body |
| `repositories/place_repository.dart` | `POST /api/places/filter` |
| `viewmodels/map_search_viewmodel.dart` | 반려동물/유모차 필터 상태 |
| `views/map_screen.dart` | 지도 화면 (지도 SDK 연동 지점) |
| `views/filter_bottom_sheet.dart` | 필터 바텀시트 |

### 4. my_history — [SB 화면 4]

| 파일 | 설명 |
|------|------|
| `models/receipt.dart` | 영수증 카드 |
| `models/stamp.dart` | 로컬 스탬프/뱃지 |
| `repositories/reward_remote_repository.dart` | `GET /api/rewards` (Spring) |
| `repositories/stamp_local_repository.dart` | SharedPreferences (로컬) |
| `viewmodels/my_history_viewmodel.dart` | 공유 상태, 스탬프 개수 |
| `views/receipt_share_screen.dart` | 원터치 공유 |
| `views/stamp_history_screen.dart` | 스탬프 이력 |

---

## 사용 패키지

| 패키지 | 용도 |
|--------|------|
| `flutter_riverpod` | ViewModel (Notifier) + DI |
| `dio` | Spring HTTP 통신 |
| `go_router` | SB 화면 라우팅 |
| `geolocator` | GPS 좌표 |
| `shared_preferences` | 로컬 스탬프 저장 |

---

## 새 feature 추가 방법

1. `lib/features/{name}/` 아래 `models`, `repositories`, `viewmodels`, `views` 생성
2. `core/constants/api_constants.dart`에 엔드포인트 추가
3. `core/di/providers.dart`에 Repository·ViewModel Provider 등록
4. `core/routing/app_router.dart`에 Route 추가

---

## 테스트 구조 (권장)

```
test/
├── core/
└── features/
    └── home_curation/
        ├── viewmodels/home_curation_viewmodel_test.dart
        └── repositories/course_repository_test.dart
```

ViewModel·Repository는 Mock Dio로 단위 테스트하기 쉽습니다.
