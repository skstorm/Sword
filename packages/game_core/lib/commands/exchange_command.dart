import 'command.dart';
import '../events/game_event.dart';
import '../events/economy_event.dart';
import '../logic/fragment_logic.dart';
import '../models/fragment.dart';
import '../models/game_state.dart';

/// 파편 교환 커맨드
class ExchangeCommand extends Command {
  final ItemType itemType;
  final int quantity;

  const ExchangeCommand({
    required this.itemType,
    this.quantity = 1,
    super.timestamp,
  });

  @override
  String? validate(GameState state, GameContext context) {
    if (state.pendingAdProtection) return 'pending_ad_protection';
    if (!const FragmentLogic().canExchange(state, itemType, quantity: quantity)) {
      return 'insufficient_fragments';
    }
    return null;
  }

  @override
  CommandResult execute(GameState state, GameContext context) {
    final result = const FragmentLogic().exchange(state, itemType, quantity: quantity);
    final events = <GameEvent>[...result.events];

    if (itemType == ItemType.goldPouch) {
      final goldGain = FragmentCost.goldPouchReward * quantity;
      events.add(GoldChangeEvent(
        amount: goldGain,
        newTotal: result.newState.playerData.gold,
        reason: 'exchange',
      ));
    }

    return CommandResult(newState: result.newState, events: events);
  }
}
