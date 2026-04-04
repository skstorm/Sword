import 'package:game_core/game_core.dart';

/// P2-37~39: Hive(로컬) + Firebase(원격) 동기화 래퍼
///
/// save() → Hive 즉시 저장 → Firebase 비동기 업로드
/// load() → 앱 시작 시 Firebase pull → Hive 반영 → Hive에서 읽기
/// 동기화 충돌: 최신 타임스탬프(lastSyncedAt) 우선
/// 오프라인: 동기화 실패 시 로컬 유지, 복귀 시 재동기화
class SyncedRepository implements StorageRepository {
  final StorageRepository local;
  final StorageRepository remote;

  bool _initialSyncDone = false;
  bool _syncInProgress = false;

  SyncedRepository({required this.local, required this.remote});

  @override
  Future<PlayerData> load() async {
    // 앱 시작 시 원격 데이터와 동기화
    if (!_initialSyncDone) {
      await _pullFromRemote();
      _initialSyncDone = true;
    }
    // 평상시에는 로컬에서 읽기 (빠름)
    return local.load();
  }

  @override
  Future<void> save(PlayerData data) async {
    // 1. Hive에 즉시 저장 (동기적으로 빠름)
    final timestamped = data.copyWith(lastSyncedAt: DateTime.now());
    await local.save(timestamped);

    // 2. Firebase에 비동기 업로드 (실패해도 로컬은 안전)
    _pushToRemote(timestamped);
  }

  /// 원격 → 로컬 동기화 (앱 시작 시)
  Future<void> _pullFromRemote() async {
    try {
      final remoteData = await remote.load();
      final localData = await local.load();

      // P2-38: 충돌 해결 — 최신 타임스탬프 우선
      final resolved = _resolveConflict(localData, remoteData);
      await local.save(resolved);
    } catch (_) {
      // P2-39: 오프라인 처리 — 동기화 실패 시 로컬 데이터 유지
      // 복귀 시 다음 save()에서 재동기화됨
    }
  }

  /// 로컬 → 원격 업로드 (비동기, fire-and-forget)
  Future<void> _pushToRemote(PlayerData data) async {
    if (_syncInProgress) return;
    _syncInProgress = true;

    try {
      await remote.save(data);
    } catch (_) {
      // P2-39: 업로드 실패 시 무시 — 로컬에는 이미 저장됨
      // 다음 save() 시 재시도
    } finally {
      _syncInProgress = false;
    }
  }

  /// P2-38: 동기화 충돌 해결 — 최신 타임스탬프(lastSyncedAt) 우선
  PlayerData _resolveConflict(PlayerData localData, PlayerData remoteData) {
    // isFirstRun인 경우 (신규 유저) 다른 쪽 사용
    if (localData.isFirstRun && !remoteData.isFirstRun) return remoteData;
    if (!localData.isFirstRun && remoteData.isFirstRun) return localData;

    // 둘 다 데이터가 있으면 최신 타임스탬프 우선
    if (remoteData.lastSyncedAt.isAfter(localData.lastSyncedAt)) {
      return remoteData;
    }
    return localData;
  }

  /// 수동 동기화 트리거 (판매/수집/파괴/백그라운드 전환 시 호출)
  Future<void> forceSync() async {
    final data = await local.load();
    await _pushToRemote(data);
  }
}
