# 인수인계 문서

## 프로젝트
- **이름**: 검강화 게임 (캐주얼 강화 시뮬레이션)
- **위치**: `C:\Work\Sword\Sword`
- **기술 스택**: Flutter + 순수 Dart (game_core)
- **Flutter SDK**: `C:\dev\flutter` (3.29.3, PATH 등록 완료)

## 프로젝트 구조
```
Sword/
├── packages/game_core/     ← 순수 Dart 패키지 (Flutter 의존성 0)
│   ├── lib/
│   │   ├── game_core.dart  ★ barrel file (Logic 비공개)
│   │   ├── models/         Sword, GameState, PlayerData, Mastery, Fragment 등
│   │   ├── logic/          enhance, economy, fragment, mastery, collection, ad_reward, game_session (비공개)
│   │   ├── commands/       Enhance, Sell, Collect, UseItem, Exchange, WatchAd, ConfirmDestroy
│   │   ├── events/         Enhance, Economy, Fragment, Mastery, Collection, Ad 이벤트
│   │   ├── engine/         GameEngine, SessionRecorder
│   │   ├── repositories/   StorageRepository, RankingRepository
│   │   ├── data/           SwordDataLoader, MasteryDataLoader
│   │   └── util/           RandomProvider, TimeProvider
│   └── test/               142 tests passing
├── app_flutter/            ← Flutter 앱
│   ├── lib/
│   │   ├── views/          title, enhance, main_shell, workshop
│   │   │   └── widgets/    sword_display, gold_indicator
│   │   ├── animations/     controller, config, basic impl
│   │   ├── bindings/       game_binding (Riverpod, StorageMode DI)
│   │   ├── repositories/   InMemory, Hive, Firebase, Synced, StorageMode
│   │   └── services/       ad_service, auth_service
│   └── assets/data/        swords.csv, mastery_levels.csv
└── doc/
    ├── plan.md             기획서
    ├── implementation-guide.md  구현계획서
    ├── tasks.md            태스크리스트
    ├── ideas.md            추가 아이디어
    ├── swords.csv          검 데이터
    ├── mastery_levels.csv  숙련도 데이터
    ├── WorkLog/            작업일지
    └── HANDOFF.md          이 파일
```

## 참조 문서 (반드시 읽을 것)
| 문서 | 경로 | 용도 |
|------|------|------|
| 기획서 | `doc/plan.md` | 게임 전체 설계, 시스템 사양, 밸런스 방향 |
| 구현계획서 | `doc/implementation-guide.md` | 아키텍처, 코드 규칙, 인터페이스 상세, P1~P4 확장 가이드 |
| 태스크리스트 | `doc/tasks.md` | Phase별 태스크 정의, 체크리스트 |
| 추가 아이디어 | `doc/ideas.md` | 미채택 아이디어 (구현 시 기획서에 반영 필요) |
| 검 데이터 | `doc/swords.csv` | 21단계 검 밸런스 (원본, app_flutter/assets/data에 복사본) |
| 숙련도 데이터 | `doc/mastery_levels.csv` | 장인 숙련도 10레벨 테이블 (원본) |
| 작업일지 | `doc/WorkLog/` | 일자별 작업 기록, 트러블슈팅 이력 |

## 진행 상황
| Phase | 상태 | 비고 |
|-------|------|------|
| Phase 0: 프로젝트 셋업 | ✅ 완료 | 미커밋 |
| Phase 1: 핵심 게임 루프 (MVP) | ✅ 완료 | 미커밋, 92 tests |
| Phase 2: 서브 시스템 | ✅ 완료 | 미커밋, 142 tests passing, flutter analyze 통과 |
| Phase 3: 소셜 & 라이브 | ❌ 미착수 | 업적, 칭호, 랭킹, 리플레이 |
| Phase 4: 폴리싱 | ❌ 미착수 | |

### Phase 2 상세
| 서브시스템 | 태스크 | 상태 |
|-----------|--------|------|
| 파편 시스템 | P2-1~8 | ✅ 완료 — fragment_logic, ExchangeCommand, UseItemCommand, 이벤트, 테스트 |
| 장인 숙련도 | P2-9~14 | ✅ 완료 — mastery_logic, MasteryDataLoader, 레벨업/할인/파편보너스, 테스트 |
| 컬렉션 | P2-15~19 | ✅ 완료 — collection_logic, CollectCommand, 이벤트, 테스트 |
| 광고 보상 | P2-20~26 | ✅ 완료 — ad_reward_logic, WatchAdCommand, ConfirmDestroyCommand, 일일제한, 부스터+주문서 중복, 테스트 |
| 뷰 | P2-27~32 | ✅ 완료 — workshop_view(숙련도/교환소/도감 3탭), enhance_view P2 업데이트, 공용 위젯, ad_service 스텁 |
| 저장 | P2-33~41 | ✅ 완료 — HiveStorageRepository, FirebaseRepository(스텁), SyncedRepository, StorageMode DI, auth_service(스텁) |

## 주의사항
- **커밋 미완료**: Phase 0 + Phase 1 + Phase 2 작업이 아직 커밋되지 않음
- **Visual Studio 미설치**: `flutter run -d windows` 불가 → `flutter run -d chrome`으로 실행
- **Phase 완료 검증 필수**: 매 Phase 완료 시 코드/구현계획서/태스크리스트 3중 대조 검증
- **barrel file 규칙**: Logic 클래스는 절대 export하지 않음
- **Logic 순수 함수 규칙**: 사이드이펙트 없음, 다른 Logic 호출 금지, Command가 조합 담당
- **Firebase 스텁**: FirebaseRepository와 AuthService는 스텁 구현 (실제 Firebase SDK 미설치). 배포 시 cloud_firestore, firebase_auth 패키지 추가 + 스텁을 실제 구현으로 교체 필요
- **광고 스텁**: AdService는 StubAdService (항상 성공). 배포 시 google_mobile_ads 패키지 추가 + 실제 AdMob 구현 필요
- **저장 모드**: game_binding.dart의 storageModeProvider로 test/local/server 전환. 현재 기본값 `local`
- **Hive 직렬화**: HiveStorageRepository에서 PlayerData ↔ JSON 변환. 필드 추가 시 _toJson/_fromJson 업데이트 필요

## 다음 작업
1. Phase 0 + Phase 1 + Phase 2 커밋 (사용자 확인 후)
2. Phase 3 진행 (tasks.md P3-1 ~ P3-15)
   - 업적/칭호 (P3-1~6)
   - 랭킹 (P3-7~10)
   - 리플레이 (P3-11~13)
   - 푸시/알림 (P3-14~15)

## 테스트 실행
```bash
export PATH="/c/dev/flutter/bin:$PATH"
cd /c/Work/Sword/Sword/packages/game_core && dart test
cd /c/Work/Sword/Sword/app_flutter && flutter analyze
```
