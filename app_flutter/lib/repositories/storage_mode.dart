import 'package:game_core/game_core.dart';
import 'in_memory_repository.dart';
import 'hive_storage_repository.dart';
import 'firebase_repository.dart';
import 'synced_repository.dart';
import '../services/auth_service.dart';

/// P2-40: 저장 모드 3종 — DI 시점에 구현체 교체로 모드 전환
enum StorageMode {
  /// 테스트용 — 메모리에만 저장, 앱 종료 시 소멸
  test,

  /// 로컬 모드 — Hive로 로컬 저장, 서버 통신 없음
  local,

  /// 서버 모드 — Hive(로컬) + Firebase(서버) 동기화
  server,
}

/// 저장 모드에 따라 적절한 StorageRepository 구현체 생성
StorageRepository createRepository(StorageMode mode, {AuthService? auth}) {
  switch (mode) {
    case StorageMode.test:
      return InMemoryRepository();
    case StorageMode.local:
      return HiveStorageRepository();
    case StorageMode.server:
      final authService = auth ?? StubAuthService();
      return SyncedRepository(
        local: HiveStorageRepository(),
        remote: FirebaseRepository(auth: authService),
      );
  }
}
