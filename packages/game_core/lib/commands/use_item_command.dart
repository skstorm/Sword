import 'command.dart';
import '../events/game_event.dart';
import '../events/fragment_event.dart';
import '../models/fragment.dart';
import '../models/game_state.dart';

/// 아이템 사용 커맨드 (보호의 부적 / 축복의 주문서)
class UseItemCommand extends Command {
  final ItemType itemType;

  const UseItemCommand({required this.itemType, super.timestamp});

  @override
  String? validate(GameState state, GameContext context) {
    if (state.pendingAdProtection) return 'pending_ad_protection';

    switch (itemType) {
      case ItemType.protectionAmulet:
        if (state.playerData.inventory.protectionAmulets <= 0) return 'no_item';
        if (state.hasActiveProtection) return 'already_protected';
      case ItemType.blessingScroll:
        if (state.playerData.inventory.blessingScrolls <= 0) return 'no_item';
      case ItemType.goldPouch:
        return 'invalid_item_type';
    }
    return null;
  }

  @override
  CommandResult execute(GameState state, GameContext context) {
    final events = <GameEvent>[];
    var s = state;

    switch (itemType) {
      case ItemType.protectionAmulet:
        final remaining = s.playerData.inventory.protectionAmulets - 1;
        s = s.copyWith(
          hasActiveProtection: true,
          playerData: s.playerData.copyWith(
            inventory: s.playerData.inventory.copyWith(
              protectionAmulets: remaining,
            ),
          ),
        );
        events.add(UseItemEvent(itemType: itemType, remainingCount: remaining));
      case ItemType.blessingScroll:
        final remaining = s.playerData.inventory.blessingScrolls - 1;
        s = s.copyWith(
          activeModifiers: [...s.activeModifiers, BlessingScrollModifier()],
          playerData: s.playerData.copyWith(
            inventory: s.playerData.inventory.copyWith(
              blessingScrolls: remaining,
            ),
          ),
        );
        events.add(UseItemEvent(itemType: itemType, remainingCount: remaining));
      case ItemType.goldPouch:
        break;
    }

    return CommandResult(newState: s, events: events);
  }
}
