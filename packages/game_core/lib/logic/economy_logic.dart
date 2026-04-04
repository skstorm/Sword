import 'logic_result.dart';
import '../events/economy_event.dart';
import '../models/game_state.dart';

/// 경제 로직 — 순수 함수 모음
class EconomyLogic {
  const EconomyLogic();
  /// 비용을 감당할 수 있는지 확인
  bool canAfford(GameState state, int cost) {
    return state.playerData.gold >= cost;
  }

  /// 골드 소비 처리
  LogicResult spendGold(GameState state, int cost) {
    final newGold = state.playerData.gold - cost;
    final newState = state.copyWith(
      playerData: state.playerData.copyWith(gold: newGold),
    );

    final event = GoldChangeEvent(
      amount: -cost,
      newTotal: newGold,
      reason: 'enhance',
    );

    return LogicResult(newState, [event]);
  }

  /// 골드 획득 처리
  LogicResult addGold(GameState state, int amount, String reason) {
    final newGold = state.playerData.gold + amount;
    final newState = state.copyWith(
      playerData: state.playerData.copyWith(gold: newGold),
    );

    final event = GoldChangeEvent(
      amount: amount,
      newTotal: newGold,
      reason: reason,
    );

    return LogicResult(newState, [event]);
  }
}
