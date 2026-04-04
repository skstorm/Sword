import '../models/player.dart';

/// 저장소 인터페이스 — 구현체(InMemory/Hive/Synced)는 외부에서 주입
abstract class StorageRepository {
  Future<PlayerData> load();
  Future<void> save(PlayerData data);
}
