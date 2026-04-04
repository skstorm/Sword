import '../commands/command.dart';
import '../events/game_event.dart';
import '../events/collection_event.dart';
import '../models/game_state.dart';

/// 컬렉션 로직 — 순수 함수 모음
class CollectionLogic {
  /// 현재 검을 컬렉션에 등록
  LogicResult collect(GameState state) {
    final level = state.currentLevel;
    final swordName = state.currentSword.name;
    final currentCollection = state.playerData.collection;

    // 수집 횟수 갱신
    final newCollected = Map<int, int>.from(currentCollection.collected);
    final isNew = !newCollected.containsKey(level);
    newCollected[level] = (newCollected[level] ?? 0) + 1;

    final newCollectionData = currentCollection.copyWith(collected: newCollected);
    final newState = state.copyWith(
      playerData: state.playerData.copyWith(collection: newCollectionData),
    );

    final events = <GameEvent>[
      CollectEvent(
        collectedLevel: level,
        collectedSwordName: swordName,
        isNewCollection: isNew,
        totalCompletion: newCollectionData.completionRate,
      ),
    ];

    // 컬렉션 완성 체크
    if (newCollectionData.uniqueCount == newCollectionData.totalCollectible) {
      events.add(const CollectionCompleteEvent());
    }

    return LogicResult(newState, events);
  }

  /// 수집 가능 여부 확인
  bool canCollect(GameState state) {
    return state.currentLevel >= 10 && state.currentSword.collectible;
  }
}
