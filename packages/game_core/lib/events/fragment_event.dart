import 'game_event.dart';
import '../models/fragment.dart';

/// 파편 획득 이벤트
class FragmentGainEvent extends GameEvent {
  final int amount;
  final int totalFragments;
  const FragmentGainEvent({required this.amount, required this.totalFragments});
}

/// 파편 교환 이벤트
class ExchangeEvent extends GameEvent {
  final ItemType itemType;
  final int fragmentsSpent;
  final int totalFragments;
  const ExchangeEvent({
    required this.itemType,
    required this.fragmentsSpent,
    required this.totalFragments,
  });
}

/// 아이템 사용 이벤트
class UseItemEvent extends GameEvent {
  final ItemType itemType;
  final int remainingCount;
  const UseItemEvent({required this.itemType, required this.remainingCount});
}
