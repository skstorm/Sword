import 'game_event.dart';

class SellEvent extends GameEvent {
  final int soldLevel;
  final String soldSwordName;
  final int goldGained;
  const SellEvent({
    required this.soldLevel,
    required this.soldSwordName,
    required this.goldGained,
  });
}

class GoldChangeEvent extends GameEvent {
  final int amount; // negative for spending, positive for earning
  final int newTotal;
  final String reason; // 'enhance', 'sell', 'ad_gold', etc.
  const GoldChangeEvent({
    required this.amount,
    required this.newTotal,
    required this.reason,
  });
}
