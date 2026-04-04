import 'package:game_core/game_core.dart';

/// 테스트/P1용 — 메모리에만 저장, 앱 종료 시 소멸
class InMemoryRepository implements StorageRepository {
  PlayerData? _data;

  @override
  Future<PlayerData> load() async {
    return _data ?? PlayerData();
  }

  @override
  Future<void> save(PlayerData data) async {
    _data = data;
  }
}
