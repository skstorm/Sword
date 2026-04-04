import 'game_event.dart';

/// 검 수집 이벤트
class CollectEvent extends GameEvent {
  final int collectedLevel;
  final String collectedSwordName;
  final bool isNewCollection;
  final double totalCompletion;
  const CollectEvent({
    required this.collectedLevel,
    required this.collectedSwordName,
    required this.isNewCollection,
    required this.totalCompletion,
  });
}

/// 컬렉션 100% 달성 이벤트
class CollectionCompleteEvent extends GameEvent {
  const CollectionCompleteEvent();
}
