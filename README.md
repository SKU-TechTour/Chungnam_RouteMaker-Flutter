# Chungnam RouteMaker — Flutter Frontend

> **Frontend**: Flutter (MVVM + Feature-first)  
> **Backend**: Spring (DDD / Layered Architecture)  

---
## Github Guidline

| Prefix | 용도 | 예시 상황 |
|--------|------|-----------|
| `feat` | 새로운 기능(Feature) 추가 | API, 비즈니스 로직, 스케줄러 등 **동작이 추가**될 때 |
| `fix` | 버그·에러 수정(Fix) | 잘못된 동작, 장애, 데이터 오류 등 **문제 해결** |
| `chore` | 빌드·인프라·설정 | 패키지, 환경 변수, 키 파일, Gradle 등 **기능과 무관한 유지보수** |
| `docs` | 문서(Documentation) | README, API 명세, 아키텍처 문서 등 |
| `refactor` | 구조 개선(Refactor) | **기능은 동일**, 코드 정리·분리·이름 변경 |
| `style` | 포맷·린트 | 세미콜론, import 정리 등 **로직 변경 없음** |

#### feat — 새 기능

```
feat: 맞춤형 3단 코스 추천 API 추가
```

#### fix — 버그 수정

```
fix: JWT 만료 시 401 대신 500이 반환되던 문제 수정
```

#### chore — 설정 변경

```
chore: Redis Docker Compose 설정 추가
```

#### docs — 문서

```
docs: Spring 아키텍처 및 Flutter 연동 가이드 README 추가
```

#### refactor — 구조 개선 (기능 동일)

```
refactor: PlaceService 필터 로직을 PlaceFilterService로 분리
```

---
## 1. 아키텍처 개요

이 프로젝트는 **MVVM(Model-View-ViewModel)** 패턴을 기반으로, 화면(스토리보드) 단위로 모듈을 나눈 **Feature-first** 구조를 사용합니다.

Spring Backend는 DDD 계층(Controller → Service → Repository → Entity)으로 설계하고, Flutter Frontend는 **화면 상태와 UI를 MVVM으로 분리**합니다. 두 프로젝트는 **REST API(JSON over HTTP)** 로 통신합니다.

```
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
```

### 계층별 역할

| Flutter 계층 | 역할 | Spring 대응 |
|---|---|---|
| **View** | UI 렌더링, 사용자 입력을 ViewModel에 전달 | 없음 (UI 전용) |
| **ViewModel** | 화면 상태 관리, UI 이벤트 처리, Repository 호출 | Controller가 받는 요청의 "화면 표현" |
| **Repository** | API·로컬·네이티브 데이터 소스 추상화 | Service를 HTTP로 호출하는 Client 역할 |
| **Model** | JSON ↔ Dart 객체 변환 | DTO / Entity |

### 핵심 설계 원칙

1. **View는 ViewModel만 안다** — Dio, API URL, MethodChannel을 View에서 직접 호출하지 않음
2. **ViewModel은 Repository만 안다** — HTTP 세부사항은 Repository에 위임
3. **Feature 간 직접 import 금지** — 공통 코드는 `core/`로, feature끼리는 독립
4. **의존성 주입은 `core/di/providers.dart` 한곳에서** — Riverpod Provider로 연결
5. **스토리보드(SB) 화면 = feature 1개** — 팀원별 담당 feature 분리 가능

---

## 2. 폴더 구조

```
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
```
