import '../commands/command.dart';
import '../events/game_event.dart';
import '../events/mastery_event.dart';
import '../models/game_state.dart';
import '../models/mastery.dart';

/// 장인 숙련도 로직 — 순수 함수 모음
class MasteryLogic {
  /// 강화 시도 시 경험치 +1, 레벨업 판정
  LogicResult addExp(GameState state, MasteryLevelTable table) {
    final newAttempts = state.playerData.mastery.totalAttempts + 1;
    final currentLevel = state.playerData.mastery.level;
    final newLevel = table.getLevelForExp(newAttempts);

    final newState = state.copyWith(
      playerData: state.playerData.copyWith(
        mastery: state.playerData.mastery.copyWith(
          totalAttempts: newAttempts,
          level: newLevel,
        ),
      ),
    );

    final events = <GameEvent>[];
    if (newLevel > currentLevel) {
      events.add(MasteryLevelUpEvent(
        newLevel: newLevel,
        reward: table.getReward(newLevel),
      ));
    }

    return LogicResult(newState, events);
  }
}
