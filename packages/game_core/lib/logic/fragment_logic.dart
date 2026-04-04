import 'logic_result.dart';
import '../events/fragment_event.dart';
import '../models/fragment.dart';
import '../models/game_state.dart';

/// 파편 로직 — 순수 함수 모음
class FragmentLogic {
  const FragmentLogic();
  /// 파괴 시 파편 지급 (기본 파편 + 숙련도 보너스)
  LogicResult giveFragments(GameState state, int fragmentBonus) {
    final baseFragments = state.currentSword.fragmentReward;
    final total = baseFragments + fragmentBonus;
    final newFragments = state.playerData.fragments + total;
    final newState = state.copyWith(
      playerData: state.playerData.copyWith(fragments: newFragments),
    );
    return LogicResult(newState, [
      FragmentGainEvent(amount: total, totalFragments: newFragments),
    ]);
  }

  /// 파편으로 아이템 교환
  LogicResult exchange(GameState state, ItemType itemType, {int quantity = 1}) {
    final cost = _getCost(itemType) * quantity;
    final newFragments = state.playerData.fragments - cost;

    var newState = state.copyWith(
      playerData: state.playerData.copyWith(fragments: newFragments),
    );

    switch (itemType) {
      case ItemType.protectionAmulet:
        newState = newState.copyWith(
          playerData: newState.playerData.copyWith(
            inventory: newState.playerData.inventory.copyWith(
              protectionAmulets: newState.playerData.inventory.protectionAmulets + quantity,
            ),
          ),
        );
      case ItemType.blessingScroll:
        newState = newState.copyWith(
          playerData: newState.playerData.copyWith(
            inventory: newState.playerData.inventory.copyWith(
              blessingScrolls: newState.playerData.inventory.blessingScrolls + quantity,
            ),
          ),
        );
      case ItemType.goldPouch:
        final goldGain = FragmentCost.goldPouchReward * quantity;
        newState = newState.copyWith(
          playerData: newState.playerData.copyWith(
            gold: newState.playerData.gold + goldGain,
          ),
        );
    }

    return LogicResult(newState, [
      ExchangeEvent(
        itemType: itemType,
        fragmentsSpent: cost,
        totalFragments: newFragments,
      ),
    ]);
  }

  /// 교환 가능 여부
  bool canExchange(GameState state, ItemType itemType, {int quantity = 1}) {
    return state.playerData.fragments >= _getCost(itemType) * quantity;
  }

  int _getCost(ItemType itemType) {
    switch (itemType) {
      case ItemType.protectionAmulet:
        return FragmentCost.protectionAmulet;
      case ItemType.blessingScroll:
        return FragmentCost.blessingScroll;
      case ItemType.goldPouch:
        return FragmentCost.goldPouch;
    }
  }
}
